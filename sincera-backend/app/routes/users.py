from fastapi import APIRouter, UploadFile, File, Form
from app.database import supabase, neo4j_driver

router = APIRouter(tags=["Users"])

@router.post("/register")
async def register_user(username: str, user_id: str = None):
    try:
        clean_username = username.lower()
        data = {"username": clean_username}
        if user_id: data["id"] = user_id
        supabase.table("profiles").upsert(data).execute()
        with neo4j_driver.session() as session:
            session.run("MERGE (u:User {username: $un}) SET u.id = $id", un=clean_username, id=user_id)
        return {"status": "success"}
    except Exception as e:
        return {"error": str(e)}, 500

@router.post("/follow")
async def follow_user(follower: str, following: str):
    try:
        p1 = supabase.table("profiles").select("id").eq("username", follower).execute()
        p2 = supabase.table("profiles").select("id").eq("username", following).execute()
        id1 = p1.data[0]['id'] if p1.data else None
        id2 = p2.data[0]['id'] if p2.data else None
        with neo4j_driver.session() as session:
            session.run("""
                MERGE (u1:User {username: $f1}) SET u1.id = $id1
                MERGE (u2:User {username: $f2}) SET u2.id = $id2
                MERGE (u1)-[:FOLLOWS]->(u2)
            """, f1=follower, f2=following, id1=id1, id2=id2)
        return {"status": "success"}
    except Exception as e:
        return {"error": str(e)}, 500

@router.get("/profile/{username}")
async def get_profile(username: str, current_user: str = None):
    try:
        res = supabase.table("profiles").select("*").eq("username", username).execute()
        if not res.data: return {"error": "Usuario no encontrado"}, 404
        user_info = res.data[0]
        
        # SOLUCIÓN 2: .order("created_at", desc=True)
        posts_res = supabase.table("posts").select("*").eq("user_id", user_info['id']).order("created_at", desc=True).execute()
        
        # SOLUCIÓN 3 y 5: Inyectar el username y avatar en los posts para que Flutter no ponga el UUID
        posts_data = posts_res.data if posts_res.data else []
        for p in posts_data:
            p["username"] = username
            p["avatar_url"] = user_info.get("avatar_url")
        
        f_count, fg_count, sigue = 0, 0, False
        with neo4j_driver.session() as session:
            f_count = session.run("MATCH (u:User {username: $u})<-[:FOLLOWS]-(f) RETURN count(f) as c", u=username).single()["c"]
            fg_count = session.run("MATCH (u:User {username: $u})-[:FOLLOWS]->(f) RETURN count(f) as c", u=username).single()["c"]
            if current_user and current_user != username:
                chk = session.run("MATCH (a:User {username: $me}), (b:User {username: $u}) RETURN COUNT { (a)-[:FOLLOWS]->(b) } > 0 as s", me=current_user, u=username).single()
                sigue = chk["s"] if chk else False

        return {
            "username": username,
            "avatar_url": user_info.get("avatar_url") or "",
            "bio": user_info.get("bio") or "",
            "posts": posts_data,
            "posts_count": len(posts_data),
            "followers": int(f_count),
            "following": int(fg_count),
            "is_following": bool(sigue)
        }
    except Exception as e:
        print(f"Error fatal en profile: {e}")
        return {"error": str(e)}, 500

@router.get("/followers/{username}")
async def get_followers(username: str):
    with neo4j_driver.session() as session:
        res = session.run("MATCH (u:User {username: $u})<-[:FOLLOWS]-(f:User) RETURN f.username as un", u=username)
        users = [r["un"] for r in res]
    if not users: return []
    p = supabase.table("profiles").select("username, avatar_url").in_("username", users).execute()
    return p.data

@router.get("/following/{username}")
async def get_following(username: str):
    with neo4j_driver.session() as session:
        res = session.run("MATCH (u:User {username: $u})-[:FOLLOWS]->(f:User) RETURN f.username as un", u=username)
        users = [r["un"] for r in res]
    if not users: return []
    p = supabase.table("profiles").select("username, avatar_url").in_("username", users).execute()
    return p.data

@router.post("/upload_avatar")
async def upload_avatar(file: UploadFile = File(...), username: str = Form(...)):
    try:
        path = f"profile_{username}.jpg"
        content = await file.read()
        supabase.storage.from_("avatars").upload(path, content, {"x-upsert": "true", "content-type": "image/jpeg"})
        url = supabase.storage.from_("avatars").get_public_url(path)
        supabase.table("profiles").update({"avatar_url": url}).eq("username", username).execute()
        return {"status": "success", "avatar_url": url}
    except Exception as e:
        return {"error": str(e)}, 500