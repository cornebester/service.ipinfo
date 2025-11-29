
def test_root(app, client):
    res = client.get('/')
    html = res.data.decode()
    assert res.status_code == 200
    assert "IPInfo service</h3><b>Hostname, machine name, container name:</b>" in html