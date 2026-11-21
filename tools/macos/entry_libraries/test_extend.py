"""Native cache occurrences can retain source and compiled payloads for the same MSL."""
from unittest import TestCase, main
from unittest.mock import patch

from extend import extend_group


def apply_stages(stages, visit):
    """The container reader visits every stage and accepts optional compiled bytes."""
    output = []
    for digest, original in stages:
        updated = visit(digest, b'unchanged source', False, original)
        output.append((digest, original if updated is None else updated))
    return output


class TestVariantCoverage(TestCase):
    @patch('extend.group', apply_stages)
    def test_unobserved_duplicate_preserves_each_occurrence(self):
        source = [('shared', b'MTLB shipped'), ('shared', b''), ('observed', b'')]
        verified = set()
        actual = extend_group(source, {'observed': b'MTLB compiled'}, verified)
        self.assertEqual(actual, [*source[:2], ('observed', b'MTLB compiled')])
        self.assertEqual(verified, {'shared', 'observed'})

    @patch('extend.group', apply_stages)
    def test_observed_duplicate_reuses_matching_shipped_library(self):
        source = [('shared', b''), ('shared', b'MTLB shipped')]
        actual = extend_group(source, {'shared': b'MTLB shipped'}, set())
        self.assertEqual(actual, [('shared', b'MTLB shipped')] * 2)


if __name__ == '__main__':
    main()
