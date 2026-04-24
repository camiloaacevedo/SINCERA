from fastapi import APIRouter, UploadFile, File, Form
from app.database import supabase, neo4j_driver, get_likes_count, add_like_to_graph

router = APIRouter(tags=["Posts"])

    
@router.get("/posts")
async def get_posts():
    try:
        response = supabase.table("posts").select("*").order("created_at", desc=True).execute()
        posts = response.data
        
        with neo4j_driver.session() as session:
            for post in posts:
                # REPARACIÓN: Si el post existe pero no tiene user_id, se lo ponemos
                session.run("""
                    MERGE (p:Post {id: $post_id})
                    SET p.user_id = $username
                """, post_id=str(post['id']), username=post['user_id'])
                
                post['likes_count'] = get_likes_count(post['id'])
            
        return posts
    except Exception as e:
        print(f"Error reparando posts: {e}")
        return {"error": str(e)}, 500

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

@router.post("/like")
async def like_post(post_id: str, username: str):
    try:
        add_like_to_graph(username, post_id)
        nuevo_total = get_likes_count(post_id)
        
        return {
            "status": "success", 
            "post_id": post_id, 
            "new_likes": nuevo_total 
        }
    except Exception as e:
        return {"error": str(e)}, 500