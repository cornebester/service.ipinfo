
def test_readiness_endpoint(app, client):
    res = client.get('/healthr')
    html = res.data.decode()
    assert res.status_code == 200
    assert "readiness check - pass" in html