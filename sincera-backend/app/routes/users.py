from fastapi import APIRouter
from app.database import supabase, neo4j_driver, add_user_to_graph

router = APIRouter(tags=["Users"])

@router.post("/register")
async def register_user(username: str):
    try:
        # 1. Registro en Supabase (Relacional)
        data = {"username": username}
        supabase.table("profiles").insert(data).execute()
        
        # 2. Registro en Neo4j (Grafos)
        add_user_to_graph(username)
        
        return {"status": "success"}
    except Exception as e:
        return {"error": str(e)}, 500

@router.get("/profile/{username}")
async def get_profile(username: str):
    try:
        with neo4j_driver.session() as session:
            # Quitamos el conteo de posts de Neo4j para evitar inconsistencias
            query = """
            MATCH (u:User {username: $username})
            OPTIONAL MATCH (u)<-[:FOLLOWS]-(f:User)
            OPTIONAL MATCH (u)-[:FOLLOWS]->(fw:User)
            RETURN 
                count(DISTINCT f) AS followers_count,
                count(DISTINCT fw) AS following_count,
                collect(DISTINCT {username: f.username}) AS followers_list,
                collect(DISTINCT {username: fw.username}) AS following_list
            """
            result = session.run(query, username=username).single()
            
            followers_list = [i for i in result["followers_list"] if i['username'] is not None]
            following_list = [i for i in result["following_list"] if i['username'] is not None]

            # Esta es la fuente de verdad para las fotos
            response = supabase.table("posts")\
                .select("*")\
                .eq("user_id", username)\
                .order("created_at", desc=True)\
                .execute()

            return {
                "username": username,
                "followers": result["followers_count"],
                "following": result["following_count"],
                "posts_count": len(response.data), # <-- Ahora contamos los datos reales de Supabase
                "followers_list": followers_list,
                "following_list": following_list,
                "photos": response.data # Mandamos el objeto completo (incluyendo IDs) para el carrusel
            }
    except Exception as e:
        print(f"Error en profile: {e}")
        return {"error": str(e)}, 500

@router.post("/follow")
async def follow_user(follower: str, following: str):
    try:
        with neo4j_driver.session() as session:
            # Usamos MATCH para asegurar que los usuarios existan antes de crear la relación
            session.run("""
                MATCH (u1:User {username: $follower})
                MATCH (u2:User {username: $following})
                MERGE (u1)-[:FOLLOWS]->(u2)
            """, follower=follower, following=following)
            
        return {"status": "success"}
    except Exception as e:
        return {"error": str(e)}, 500