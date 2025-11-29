
def test_liveness_endpoint(app, client):
    res = client.get('/healthl')
    html = res.data.decode()
    assert res.status_code == 200
    assert "liveness check - pass" in html