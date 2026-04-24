from fastapi import FastAPI
from app.routes import posts, users, interactions

app = FastAPI(title="Sincera API")

app.include_router(posts.router)
app.include_router(users.router)
app.include_router(interactions.router)

@app.get("/")
async def root():
    return {"message": "Sincera API Online - Estructura Modularizada"}