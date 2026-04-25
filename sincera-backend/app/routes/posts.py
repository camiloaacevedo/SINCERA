from fastapi import APIRouter, UploadFile, File, Form
from app.database import supabase, neo4j_driver, get_likes_count, add_like_to_graph
from fastapi import HTTPException

router = APIRouter(tags=["Posts"])

@router.post("/upload")
async def upload_photo(file: UploadFile = File(...), user_id: str = Form(...)):
    try:
        # 1. BUSCAR EL UUID REAL
        profile_res = supabase.table("profiles").select("id, username").eq("username", user_id).execute()
        
        if profile_res.data:
            real_uuid = profile_res.data[0]['id']
            username = profile_res.data[0]['username']
        else:
            uuid_res = supabase.table("profiles").select("id, username").eq("id", user_id).execute()
            if uuid_res.data:
                real_uuid = uuid_res.data[0]['id']
                username = uuid_res.data[0]['username']
            else:
                return {"error": f"El perfil '{user_id}' no existe."}, 400

        # 2. SUBIR AL STORAGE
        file_path = f"{username}/{file.filename}"
        file_content = await file.read()
        supabase.storage.from_("photos").upload(file_path, file_content)
        public_url = supabase.storage.from_("photos").get_public_url(file_path)

        # 3. GUARDAR EN TABLA POSTS
        data = {"user_id": real_uuid, "image_url": public_url}
        res = supabase.table("posts").insert(data).execute()
        
        # 4. NEO4J (CAMBIO: SET u.id = $real_uuid para consistencia)
        new_post = res.data[0]
        with neo4j_driver.session() as session:
            session.run("""
                MERGE (u:User {username: $username})
                SET u.id = $real_uuid
                MERGE (p:Post {id: $post_id})
                MERGE (u)-[:POSTED]->(p)
            """, username=username, real_uuid=real_uuid, post_id=str(new_post['id']))
        
        return {"status": "success", "url": public_url}

    except Exception as e:
        print(f"Error crítico en upload_photo: {e}")
        return {"error": str(e)}, 500
    
@router.get("/posts")
async def get_all_posts(current_user: str = None):
    try:
        res = supabase.table("posts") \
            .select("id, image_url, created_at, user_id, profiles(username, avatar_url)") \
            .order("created_at", desc=True) \
            .execute()
        
        posts_data = res.data if res.data else []

        # 2. Neo4j: Likes Y SEGUIMIENTO (NUEVO)
        liked_post_ids = set()
        followed_users = set() # NUEVO: Para saber a quién seguimos
        
        if current_user:
            with neo4j_driver.session() as session:
                # Obtener Likes
                res_likes = session.run("""
                    MATCH (u:User {username: $username})-[:LIKES]->(p:Post)
                    RETURN p.id AS post_id
                """, username=current_user)
                liked_post_ids = {str(record["post_id"]) for record in res_likes}

                # NUEVO: Obtener Seguidores (Esto evita que el botón se resetee)
                res_follows = session.run("""
                    MATCH (u:User {username: $username})-[:FOLLOWS]->(followed:User)
                    RETURN followed.username AS username
                """, username=current_user)
                followed_users = {record["username"] for record in res_follows}

        # 3. Formateamos la respuesta
        final_posts = []
        for p in posts_data:
            post_id_str = str(p['id'])
            perfil = p.get('profiles')
            nombre_real = perfil.get('username') if perfil else "Usuario"
            foto_perfil = perfil.get('avatar_url') if perfil else None

            final_posts.append({
                "id": post_id_str,
                "image_url": p['image_url'],
                "created_at": p['created_at'],
                "username": nombre_real,
                "avatar_url": foto_perfil,
                "likes": get_likes_count(post_id_str),
                "liked": post_id_str in liked_post_ids,
                "already_following": nombre_real in followed_users, # NUEVO: Enviamos esto al Frontend
                "user_id": p.get('user_id')
            })

        return final_posts

    except Exception as e:
        print(f"Error en get_all_posts: {e}")
        return []
    
@router.post("/unfollow")
async def unfollow_user(data: dict):
    follower = data.get("follower")
    followed = data.get("followed")
    
    if not follower or not followed:
        # Usamos HTTPException para que FastAPI lo maneje correctamente
        raise HTTPException(status_code=400, detail="Faltan datos")

    # Consulta para borrar la relación en Neo4j
    query = """
    MATCH (u:User {username: $follower})-[r:FOLLOWS]->(t:User {username: $followed})
    DELETE r
    """
    
    try:
        # IMPORTANTE: Usar 'neo4j_driver', que es como lo tienes definido arriba
        with neo4j_driver.session() as session:
            session.run(query, follower=follower, followed=followed)
        
        return {"message": f"Dejaste de seguir a {followed}"}
    except Exception as e:
        print(f"Error al dejar de seguir: {e}")
        raise HTTPException(status_code=500, detail=str(e))