import os
from dotenv import load_dotenv
from supabase import create_client
from neo4j import GraphDatabase

load_dotenv()

supabase = create_client(os.getenv("SUPABASE_URL"), os.getenv("SUPABASE_KEY"))
neo4j_driver = GraphDatabase.driver(
    os.getenv("NEO4J_URI"), 
    auth=(os.getenv("NEO4J_USER"), os.getenv("NEO4J_PASSWORD"))
)

def get_likes_count(post_id):
    with neo4j_driver.session() as session:
        result = session.run("""
            MATCH (p:Post {id: $post_id})<-[:LIKES]-()
            RETURN count(*) as total
        """, post_id=str(post_id))
        return result.single()["total"]
    
def add_user_to_graph(username):
    with neo4j_driver.session() as session:
        session.run("MERGE (u:User {username: $username})", username=username)

def add_like_to_graph(username, post_id):
    with neo4j_driver.session() as session:
        session.run("""
            MERGE (u:User {username: $username})
            MERGE (p:Post {id: $post_id})
            MERGE (u)-[:LIKES]->(p)
        """, username=username, post_id=str(post_id))