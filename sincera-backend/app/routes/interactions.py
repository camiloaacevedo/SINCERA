from fastapi import APIRouter
from app.database import neo4j_driver, supabase

router = APIRouter(tags=["Interactions"])

@router.get("/feed/following/{username}")
async def get_following_feed(username: str):
    try:
        with neo4j_driver.session() as session:
            query = """
            MATCH (me:User {username: $username})-[:FOLLOWS]->(amigo:User)
            WHERE amigo.id IS NOT NULL
            RETURN amigo.id AS amigo_id
            """
            result = session.run(query, username=username)
            amigos_ids = [record["amigo_id"] for record in result]

            if not amigos_ids:
                return []

            response = supabase.table("posts")\
                .select("*, profiles(username, avatar_url)")\
                .in_("user_id", amigos_ids)\
                .order("created_at", desc=True)\
                .execute()
            
            # SOLUCIÓN 1: Aplanar los datos para que Flutter encuentre 'username' y 'avatar_url' directo
            data = response.data if response.data else []
            for p in data:
                if 'profiles' in p and p['profiles']:
                    p['username'] = p['profiles'].get('username')
                    p['avatar_url'] = p['profiles'].get('avatar_url')
            return data
    except Exception as e:
        print(f"Error en feed siguiendo: {e}")
        return []
    
@router.post("/like")
async def toggle_like(post_id: str, username: str):
    try:
        with neo4j_driver.session() as session:
            check_query = """
                MATCH (u:User {username: $u})-[r:LIKES]->(p:Post {id: $pid})
                RETURN r IS NOT NULL as existe
            """
            result = session.run(check_query, u=username, pid=str(post_id)).single()
            ya_existe = result["existe"] if result else False

            if ya_existe:
                session.run("MATCH (u:User {username: $u})-[r:LIKES]->(p:Post {id: $pid}) DELETE r", u=username, pid=str(post_id))
                return {"liked": False}
            else:
                session.run("""
                    MERGE (u:User {username: $u})
                    MERGE (p:Post {id: $pid})
                    MERGE (u)-[:LIKES]->(p)
                """, u=username, pid=str(post_id))
                return {"liked": True}
    except Exception as e:
        return {"error": str(e)}, 500