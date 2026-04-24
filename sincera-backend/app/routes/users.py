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
            # Esta consulta cuenta seguidores, seguidos y posts en un solo viaje al grafo
            query = """
            MATCH (u:User {username: $username})
            OPTIONAL MATCH (u)<-[:FOLLOWS]-(follower:User)
            OPTIONAL MATCH (u)-[:FOLLOWS]->(following:User)
            OPTIONAL MATCH (u)-[:POSTED]->(p:Post)
            RETURN 
                count(DISTINCT follower) AS followers,
                count(DISTINCT following) AS following,
                count(DISTINCT p) AS posts_count
            """
            result = session.run(query, username=username).single()
            
            # También traemos las fotos del usuario desde Supabase
            response = supabase.table("posts")\
                .select("image_url")\
                .eq("user_id", username)\
                .order("created_at", desc=True)\
                .execute()

            return {
                "username": username,
                "followers": result["followers"],
                "following": result["following"],
                "posts_count": result["posts_count"],
                "photos": response.data
            }
    except Exception as e:
        return {"error": str(e)}, 500

@router.post("/follow")
async def follow_user(follower: str, following: str):
    try:
        with neo4j_driver.session() as session:
            # Creamos la relación de seguimiento entre dos usuarios
            session.run("""
                MERGE (u1:User {username: $follower})
                MERGE (u2:User {username: $following})
                MERGE (u1)-[:FOLLOWS]->(u2)
            """, follower=follower, following=following)
            
        print(f"¡{follower} ahora sigue a {following}!")
        return {"status": "success"}
    except Exception as e:
        return {"error": str(e)}, 500