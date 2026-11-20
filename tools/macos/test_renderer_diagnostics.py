import unittest

from renderer_diagnostics import engine_diagnostics


class RendererDiagnosticsTest(unittest.TestCase):
    def test_interleaved_shader_log_preserves_metal_capability_warning(self):
        warning = 'WARNING: Metal does not support LOD bias for samplers.'
        self.assertEqual(engine_diagnostics(['Shader cache miss for Sce' + warning]), [warning])

    def test_device_and_lifetime_errors_survive_an_interrupted_stdout_line(self):
        messages = ['ERROR: Vulkan device was lost.', 'SCRIPT ERROR: Parse Error', 'Leaked instance: Node']
        self.assertEqual(engine_diagnostics(['Loading cache ' + message for message in messages]), messages)

    def test_ordinary_verbose_records_remain_clean(self):
        self.assertEqual(engine_diagnostics(['Loading cache for shader...', '[mvk-info] Destroyed VkDevice.']), [])


if __name__ == '__main__':
    unittest.main()
