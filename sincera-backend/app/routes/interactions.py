from fastapi import APIRouter
from app.database import neo4j_driver, supabase, get_likes_count

router = APIRouter(tags=["Interactions"])

@router.get("/feed/following/{username}")
async def get_following_feed(username: str):
    try:
        with neo4j_driver.session() as session:
            # 1. Buscamos a quién sigues en Neo4j
            query_amigos = """
            MATCH (me:User {username: $username})-[:FOLLOWS]->(amigo:User)
            RETURN amigo.username AS amigo_nombre
            """
            result = session.run(query_amigos, username=username)
            amigos = [record["amigo_nombre"] for record in result]

            if not amigos:
                return []

            # 2. Buscamos los posts en Supabase
            response = supabase.table("posts")\
                .select("*")\
                .in_("user_id", amigos)\
                .order("created_at", desc=True)\
                .execute()
            
            posts_data = response.data
            
            # 3. ENRIQUECIMIENTO CON NEO4J (La clave de la sincronización)
            for post in posts_data:
                post_id = str(post['id'])
                
                # A. Contar LIKES reales (Igual que en Global)
                count_res = session.run("""
                    OPTIONAL MATCH (:User)-[r:LIKED]->(p:Post {id: $pid})
                    RETURN count(r) AS c
                """, pid=post_id).single()
                post['likes_count'] = count_res["c"]

                # B. Verificar si YO le di like
                like_check = session.run("""
                    MATCH (u:User {username: $u})-[:LIKED]->(p:Post {id: $pid}) 
                    RETURN p
                """, u=username, pid=post_id).single()
                post['user_has_liked'] = like_check is not None
                
                # C. Forzar true porque estamos en el feed de seguidos
                post['already_following'] = True
                
            return posts_data
            
    except Exception as e:
        print(f"Error en feed siguiendo: {e}")
        return []
    
@router.post("/like")
async def like_post(post_id: str, username: str):
    try:
        with neo4j_driver.session() as session:
            # Esta consulta es un "Toggle":
            # 1. Busca si existe la relación LIKED entre el usuario y el post
            # 2. Si existe, la borra (Unlike)
            # 3. Si no existe, la crea (Like)
            query = """
            MATCH (u:User {username: $u}), (p:Post {id: $pid})
            OPTIONAL MATCH (u)-[r:LIKED]->(p)
            WITH u, p, r
            CALL apoc.do.when(
                r IS NOT NULL,
                'DELETE r RETURN false AS liked',
                'MERGE (u)-[:LIKED]->(p) RETURN true AS liked',
                {r:r, u:u, p:p}
            ) YIELD value
            RETURN value.liked AS liked_now
            """
            # Nota: Si no tienes instalado APOC en Neo4j, usa esta versión más simple:
            simple_query = """
            MATCH (u:User {username: $u}), (p:Post {id: $pid})
            OPTIONAL MATCH (u)-[r:LIKED]->(p)
            FOREACH (_ IN CASE WHEN r IS NOT NULL THEN [1] ELSE [] END | DELETE r)
            FOREACH (_ IN CASE WHEN r IS NULL THEN [1] ELSE [] END | MERGE (u)-[:LIKED]->(p))
            RETURN r IS NULL AS liked_now
            """
            
            result = session.run(simple_query, u=username, pid=post_id).single()
            
        return {"status": "success", "is_liked": result["liked_now"]}
    except Exception as e:
        print(f"Error en toggle like: {e}")
        return {"error": str(e)}, 500