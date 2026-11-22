// Colour maths for theme fades. Mixing two colours halfway in plain RGB goes
// through muddy greys (blue + yellow = grey). OKLab is a colour space where
// a straight line between two colours looks like an even change to our eyes,
// so the fade from one theme to the next stays clean.
.pragma library

function toLinear(c) {
    return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
}
function toGamma(c) {
    return c <= 0.0031308 ? c * 12.92 : 1.055 * Math.pow(c, 1 / 2.4) - 0.055;
}

// a Qt color (r, g, b, a from 0 to 1) -> [L, a, b, alpha]
function toOklab(color) {
    const r = toLinear(color.r), g = toLinear(color.g), b = toLinear(color.b);
    const l = Math.cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
    const m = Math.cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
    const s = Math.cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
    return [
        0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
        1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
        0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s,
        color.a
    ];
}

// [L, a, b, alpha] -> [r, g, b, alpha], each 0..1
function fromOklab(lab) {
    const l = Math.pow(lab[0] + 0.3963377774 * lab[1] + 0.2158037573 * lab[2], 3);
    const m = Math.pow(lab[0] - 0.1055613458 * lab[1] - 0.0638541728 * lab[2], 3);
    const s = Math.pow(lab[0] - 0.0894841775 * lab[1] - 1.2914855480 * lab[2], 3);
    const clamp = x => Math.max(0, Math.min(1, x));
    return [
        clamp(toGamma(4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s)),
        clamp(toGamma(-1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s)),
        clamp(toGamma(-0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s)),
        lab[3]
    ];
}

// the colour a fraction t (0..1) of the way from one OKLab colour to another
function mix(fromLab, toLab, t) {
    return fromOklab(fromLab.map((v, i) => v + (toLab[i] - v) * t));
}
