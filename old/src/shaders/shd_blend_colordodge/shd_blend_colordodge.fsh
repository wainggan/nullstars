
varying vec4 v_color;
varying vec2 v_coord;
varying vec2 v_screen;
uniform sampler2D u_destination;

void main()
{
	
	//Sample the source and destination textures
	vec4 src = texture2D(gm_BaseTexture, v_coord) * v_color;
	vec4 dst = texture2D(u_destination, v_screen);
	
	vec4 col = dst / (1.0 - min(src, vec4(0.99999)));
	
	col.rgb = mix(dst.rgb, col.rgb, src.a);
	col.a = src.a + dst.a * (1.0 - src.a);

	gl_FragColor = col;
}
