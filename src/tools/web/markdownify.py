"""Markdown conversion helper for web_fetch.

This module converts HTML, JSON, XML, and plain text payloads into
lightweight Markdown along with a concise preview snippet. It is designed
for use as a small CLI invoked by Bash wrappers and therefore avoids
third-party dependencies.

Usage:
    python src/tools/web/markdownify.py --path /tmp/body --content-type text/html --limit 400

The script prints a JSON object with `markdown` and `preview` keys on
success and exits non-zero on conversion failures.
"""

from __future__ import annotations

import argparse
import json
import logging
from html.parser import HTMLParser
from pathlib import Path
from typing import Iterable

_LOGGER = logging.getLogger(__name__)


class _HTMLTextExtractor(HTMLParser):
    """Extracts readable text from HTML content.

    Block-level elements insert line breaks to preserve structure in the
    resulting Markdown.
    """

    _BLOCK_TAGS = {
        "p",
        "div",
        "section",
        "article",
        "ul",
        "ol",
        "li",
        "br",
        "hr",
        "table",
        "tr",
        "td",
        "th",
        "header",
        "footer",
    }

    def __init__(self) -> None:
        super().__init__()
        self._parts: list[str] = []

    def handle_starttag(self, tag: str, attrs: Iterable[tuple[str, str | None]]) -> None:  # noqa: ARG002
        if tag.lower() in {"br", "p", "div", "li", "tr"}:
            self._parts.append("\n")

    def handle_endtag(self, tag: str) -> None:
        if tag.lower() in self._BLOCK_TAGS:
            self._parts.append("\n")

    def handle_data(self, data: str) -> None:
        stripped = data.strip()
        if stripped:
            self._parts.append(stripped + " ")

    def text(self) -> str:
        joined = "".join(self._parts)
        normalized = "\n".join(line.strip() for line in joined.splitlines() if line.strip())
        return normalized.strip()


def _normalize_content_type(raw_content_type: str) -> str:
    return raw_content_type.split(";")[0].strip().lower()


def _convert_html(body: str) -> str:
    extractor = _HTMLTextExtractor()
    extractor.feed(body)
    text = extractor.text()
    if not text:
        return ""
    return text


def _convert_json(body: str) -> str:
    parsed = json.loads(body)
    pretty = json.dumps(parsed, indent=2, ensure_ascii=False)
    return f"```json\n{pretty}\n```"


def _convert_xml(body: str) -> str:
    try:
        from xml.dom import minidom
    except ImportError as exc:  # pragma: no cover - stdlib always available
        raise ValueError("xml.dom.minidom unavailable") from exc

    parsed = minidom.parseString(body.encode("utf-8", errors="replace"))
    pretty = parsed.toprettyxml(indent="  ")
    return f"```xml\n{pretty}\n```"


def _convert_plain(body: str) -> str:
    return body.strip()


def _build_preview(markdown: str, limit: int) -> str:
    if limit < 1:
        raise ValueError("preview limit must be positive")
    if len(markdown) <= limit:
        return markdown
    ellipsis = "…"
    truncated_len = max(0, limit - len(ellipsis))
    return markdown[:truncated_len] + ellipsis


def convert_to_markdown(body: str, content_type: str, limit: int) -> tuple[str, str]:
    """Convert an HTTP response body to Markdown and preview snippet.

    Args:
        body: Raw HTTP response body decoded as text.
        content_type: Content type string used to select a converter.
        limit: Maximum number of characters for the preview snippet.

    Returns:
        Tuple of the full Markdown text and the truncated preview snippet.

    Raises:
        ValueError: When conversion cannot be performed for the content type.
    """

    normalized_type = _normalize_content_type(content_type)
    if "html" in normalized_type:
        markdown = _convert_html(body)
    elif "json" in normalized_type:
        markdown = _convert_json(body)
    elif "xml" in normalized_type:
        markdown = _convert_xml(body)
    elif normalized_type.startswith("text/"):
        markdown = _convert_plain(body)
    else:
        raise ValueError(f"Unsupported content type for markdown conversion: {content_type}")

    if not markdown:
        raise ValueError("Empty markdown output after conversion")

    preview = _build_preview(markdown, limit)
    return markdown, preview


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Convert HTTP response bodies to Markdown")
    parser.add_argument("--path", required=True, help="Path to the body file")
    parser.add_argument("--content-type", required=True, help="Content type of the body")
    parser.add_argument("--limit", required=True, type=int, help="Preview snippet character limit")
    return parser.parse_args()


def main() -> int:
    args = _parse_args()
    body_path = Path(args.path)
    try:
        body_text = body_path.read_text(encoding="utf-8", errors="replace")
    except OSError as err:
        _LOGGER.error("Failed to read body file: %s", err)
        return 1

    try:
        markdown, preview = convert_to_markdown(body_text, args.content_type, args.limit)
    except Exception as err:  # noqa: BLE001
        _LOGGER.warning("Markdown conversion failed: %s", err)
        return 1

    print(json.dumps({"markdown": markdown, "preview": preview}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
