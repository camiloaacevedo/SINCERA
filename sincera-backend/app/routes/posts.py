from fastapi import APIRouter, UploadFile, File, Form
from app.database import supabase, neo4j_driver, get_likes_count, add_like_to_graph

router = APIRouter(tags=["Posts"])

    
@router.get("/posts")
async def get_posts(current_user: str = None):
    # 1. Traemos los posts de Supabase
    response = supabase.table("posts").select("*, profiles(avatar_url)").order("created_at", desc=True).execute()
    posts = response.data

    with neo4j_driver.session() as session:
        for post in posts:
            post_id = str(post['id'])
            
            # 2. Usamos OPTIONAL MATCH para que si no hay likes, devuelva 0 en lugar de un error/warning
            count_res = session.run("""
                OPTIONAL MATCH (:User)-[r:LIKED]->(p:Post {id: $pid})
                RETURN count(r) AS c
            """, pid=post_id).single()
            
            # Sobreescribimos el valor que venía de Supabase con el real de Neo4j
            post['likes_count'] = count_res["c"]

            # 3. Verificar si el usuario actual le dio like (para el corazón rojo)
            if current_user:
                like_check = session.run(
                    "MATCH (u:User {username: $u})-[:LIKED]->(p:Post {id: $pid}) RETURN p",
                    u=current_user, pid=post_id
                ).single()
                post['user_has_liked'] = like_check is not None
                
                # 4. Verificar si ya lo sigue (para el botón seguir)
                follow_check = session.run(
                    "MATCH (u:User {username: $u})-[:FOLLOWS]->(:User {username: $target}) RETURN u",
                    u=current_user, target=post['user_id']
                ).single()
                post['already_following'] = follow_check is not None
            else:
                post['user_has_liked'] = False
                post['already_following'] = False

    return posts

@router.post("/upload")
async def upload_photo(file: UploadFile = File(...), user_id: str = Form(...)):
    try:
        file_path = f"{user_id}/{file.filename}"
        file_content = await file.read()
        
        # 1. Subir al Storage
        supabase.storage.from_("photos").upload(file_path, file_content)
        
        # 2. Obtener URL y guardar en tabla posts de Supabase
        public_url = supabase.storage.from_("photos").get_public_url(file_path)
        data = {"user_id": user_id, "image_url": public_url}
        # Guardamos el resultado para sacar el ID generado por Supabase
        res = supabase.table("posts").insert(data).execute()
        new_post = res.data[0] # Aquí tenemos el ID real
        
        # 3. --- LA PIEZA CLAVE PARA NEO4J ---
        with neo4j_driver.session() as session:
            session.run("""
                MERGE (u:User {username: $username})
                MERGE (p:Post {id: $post_id})
                SET p.user_id = $username
                MERGE (u)-[:POSTED]->(p)
            """, username=user_id, post_id=str(new_post['id']))
        
        return {"message": "Post creado y registrado en grafo", "url": public_url}
    except Exception as e:
        print(f"Error en upload: {e}")
        return {"error": str(e)}, 500