import unittest
from urllib.parse import urlparse

from app import serve


class PageCase(unittest.TestCase):
    def setUp(self) -> None:
        serve.app.config['TESTING'] = True
        self.app = serve.app.test_client()

    def test_index_load(self) -> None:
        self.page_test('/', b'Albert Wang')

    def test_resume_load(self) -> None:
        self.page_test('/resume', b'R&eacute;sum&eacute;')

    def test_projects_load(self) -> None:
        self.page_test('/projects', b'Projects')

    def test_notes_load(self) -> None:
        self.page_test('/notes', b'Notes')

    def test_shelf_load(self) -> None:
        self.page_test('/shelf', b'Shelf')

    def test_reference(self) -> None:
        self.page_test('/reference', b'Reference')

    def test_about_load(self) -> None:
        self.page_test('/about', b'Contact')

    def test_robots_load(self) -> None:
        self.page_test('/robots.txt', b'')

    def test_security_load(self) -> None:
        self.page_test('/.well-known/security.txt', b'Contact')

    def test_humans_load(self) -> None:
        self.page_test('/humans.txt', b'albertyw')

    def test_health_load(self) -> None:
        self.page_test('/health', b'ok')

    def test_sitemap_load(self) -> None:
        self.page_test('/sitemap.xml', b'xml')

    def test_not_found(self) -> None:
        response = self.app.get('/asdf')
        self.assertEqual(response.status_code, 404)
        self.assertIn(b'Not Found', response.get_data())

    def test_note_load(self) -> None:
        self.page_test('/note/fibonaccoli', b'Romanesco')

    def test_note_capital_load(self) -> None:
        response = self.app.get('/note/Fibonaccoli')
        self.assertEqual(response.status_code, 302)
        self.assertEqual(urlparse(response.location).path, '/note/fibonaccoli')

    def test_atom_feed_load(self) -> None:
        self.page_test('/atom.xml', b'xml')

    def test_nonexistent_note_load(self) -> None:
        response = self.app.get('/note/asdf')
        self.assertEqual(response.status_code, 404)

    def page_test(self, path: str, string: bytes) -> None:
        response = self.app.get(path)
        self.assertEqual(response.status_code, 200)
        self.assertIn(string, response.get_data())
        response.close()
