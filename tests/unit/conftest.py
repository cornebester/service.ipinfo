import pytest

from src.application import application as flask_app

@pytest.fixture
def app():
    yield flask_app
    
@pytest.fixture
def client(app):
    return app.test_client()