//
// Simple passthrough fragment shader
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform float u_wide;
uniform vec2 u_texel;

void main()
{
	
	vec4 spot = texture2D(gm_BaseTexture, v_vTexcoord);
	float collect = 0.0;
	
	for (float i = 0.0; i < u_wide; i += 1.0) {
		float off = i + 1.0;
		collect += texture2D(gm_BaseTexture, v_vTexcoord + vec2(1.0, 0.0) * off * u_texel).a;
		collect += texture2D(gm_BaseTexture, v_vTexcoord + vec2(0.0, 1.0) * off * u_texel).a;
		collect += texture2D(gm_BaseTexture, v_vTexcoord - vec2(1.0, 0.0) * off * u_texel).a;
		collect += texture2D(gm_BaseTexture, v_vTexcoord - vec2(0.0, 1.0) * off * u_texel).a;
	}
	
	gl_FragColor = mix(vec4(v_vColour.rgb, min(collect, 1.0) * v_vColour.a), spot, spot.a);
}
