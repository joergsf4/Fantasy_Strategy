// Farbraum-Ausgleich zwischen den Renderern.
// Alle Farben dieses Spiels sind fuer den Compatibility-Renderer (OpenGL) abgestimmt: Dort rechnen die eigenen Shader
// mit sRGB-Werten (Farbkonstanten, Vertexfarben und Texturen gleichermassen). Forward+ und Mobile (Metal) erwarten
// ALBEDO und EMISSION linear. Darum rechnen die Shader ueberall in sRGB (Texturen und Farb-Uniforms ohne source_color)
// und geben das Ergebnis mit LIN() aus: unter OpenGL unveraendert, unter Metal nach linear umgerechnet.
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
#define LIN(c) (c)
#else
vec3 farbraum_lin(vec3 c) {
	c = max(c, vec3(0.0));
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}
#define LIN(c) farbraum_lin(c)
#endif
