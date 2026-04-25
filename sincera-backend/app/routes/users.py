from fastapi import APIRouter
from app.database import supabase, neo4j_driver, add_user_to_graph

router = APIRouter(tags=["Users"])

@router.post("/register")
async def register_user(username: str):
    try:
        data = {"username": username}
        supabase.table("profiles").insert(data).execute()
        add_user_to_graph(username)
        return {"status": "success"}
    except Exception as e:
        return {"error": str(e)}, 500

@router.get("/profile/{username}")
async def get_profile(username: str, current_user: str = None):
    try:
        with neo4j_driver.session() as session:
            # 1. Consultamos datos generales del perfil (Esto ya lo tienes)
            query = """
            MATCH (u:User {username: $username})
            OPTIONAL MATCH (u)<-[:FOLLOWS]-(f:User)
            OPTIONAL MATCH (u)-[:FOLLOWS]->(fw:User)
            RETURN 
                count(DISTINCT f) AS followers_count,
                count(DISTINCT fw) AS following_count,
                collect(DISTINCT {username: f.username}) AS followers_list,
                collect(DISTINCT {username: fw.username}) AS following_list,
                EXISTS((:User {username: $current_user})-[:FOLLOWS]->(u)) AS already_following
            """
            result = session.run(query, username=username, current_user=current_user).single()
            
            # 2. Consultamos las fotos en Supabase
            response = supabase.table("posts")\
                .select("*")\
                .eq("user_id", username)\
                .order("created_at", desc=True)\
                .execute()
            
            photos = response.data

            for post in photos:
                post_id = str(post['id'])
                
                # A. Contar likes totales
                count_res = session.run("""
                    OPTIONAL MATCH (:User)-[r:LIKED]->(p:Post {id: $pid})
                    RETURN count(r) AS c
                """, pid=post_id).single()
                post['likes_count'] = count_res["c"]

                # B. Verificar si el usuario actual (tú) le dio like
                if current_user:
                    like_check = session.run(
                        "MATCH (u:User {username: $u})-[:LIKED]->(p:Post {id: $pid}) RETURN p",
                        u=current_user, pid=post_id
                    ).single()
                    post['user_has_liked'] = like_check is not None
                else:
                    post['user_has_liked'] = False

            return {
                "username": username,
                "followers_count": result["followers_count"],
                "following_count": result["following_count"],
                "posts_count": len(photos),
                "followers_list": [i for i in result["followers_list"] if i.get('username')],
                "following_list": [i for i in result["following_list"] if i.get('username')],
                "already_following": result["already_following"],
                "photos": photos
            }
    except Exception as e:
        print(f"Error en profile: {e}")
        return {"error": str(e)}, 500

@router.post("/follow")
async def follow_user(follower: str, following: str):
    try:
        with neo4j_driver.session() as session:
            session.run("""
                MATCH (u1:User {username: $follower})
                MATCH (u2:User {username: $following})
                MERGE (u1)-[:FOLLOWS]->(u2)
            """, follower=follower, following=following)
        return {"status": "success"}
    except Exception as e:
        return {"error": str(e)}, 500