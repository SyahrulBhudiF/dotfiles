import { Theme } from "@mariozechner/pi-coding-agent";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

/**
 * Extension that overrides markdown bold and italic formatting to use colors instead.
 *
 * It monkey-patches the Theme prototype so it works across all themes
 * and doesn't require polling.
 */
const ORIGINALS_KEY = Symbol.for("custom-formatting.original-theme-methods");

type ThemeOriginals = {
  bold: Theme["bold"];
  italic: Theme["italic"];
};

export default function (pi: ExtensionAPI) {
  const globalWithOriginals = globalThis as typeof globalThis & {
    [ORIGINALS_KEY]?: ThemeOriginals;
  };

  const originals = globalWithOriginals[ORIGINALS_KEY] ?? {
    bold: Theme.prototype.bold,
    italic: Theme.prototype.italic,
  };
  globalWithOriginals[ORIGINALS_KEY] = originals;

  // Override bold to use 'warning' color (usually yellow/orange).
  // Some TUI render paths call theme methods without binding `this`; never crash there.
  Theme.prototype.bold = function(this: Theme | undefined, text: string) {
    if (!this || typeof this.fg !== "function") return text;
    return originals.bold.call(this, this.fg("mdHeading", text));
  };

  // Override italic to use 'accent' color (usually teal/cyan).
  Theme.prototype.italic = function(this: Theme | undefined, text: string) {
    if (!this || typeof this.fg !== "function") return text;
    return originals.italic.call(this, this.fg("accent", text));
  };

  // Restore originals on shutdown
  pi.on("session_shutdown", () => {
    Theme.prototype.bold = originals.bold;
    Theme.prototype.italic = originals.italic;
  });
}
