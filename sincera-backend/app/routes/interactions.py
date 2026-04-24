from fastapi import APIRouter
from app.database import neo4j_driver, supabase, get_likes_count

router = APIRouter(tags=["Interactions"])

@router.get("/feed/following/{username}")
async def get_following_feed(username: str):
    try:
        with neo4j_driver.session() as session:
            # Buscamos a quién sigues en Neo4j
            query = """
            MATCH (me:User {username: $username})-[:FOLLOWS]->(amigo:User)
            RETURN amigo.username AS amigo_nombre
            """
            result = session.run(query, username=username)
            amigos = [record["amigo_nombre"] for record in result]

            if not amigos:
                return []

            # Buscamos los posts de esos amigos en Supabase
            # En get_following_feed
            response = supabase.table("posts")\
                .select("*, created_at")\
                .in_("user_id", amigos)\
                .order("created_at", desc=True)\
                .execute()
            
            posts_data = response.data
            for post in posts_data:
                post['likes_count'] = get_likes_count(post['id'])
                
            return posts_data
    except Exception as e:
        print(f"Error en feed siguiendo: {e}")
        return []