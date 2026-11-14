shader_type canvas_item;
render_mode unshaded;
uniform int kind=0;
uniform int pose=0;
uniform float phase=0.0;
uniform float progress=0.0;
uniform float hurt=0.0;
varying vec4 skin_tint;

void vertex(){
	skin_tint=COLOR;
	vec2 uv=UV;
	float lower=smoothstep(0.57,0.91,uv.y);
	float upper=1.0-smoothstep(0.40,0.76,uv.y);
	float limb=(uv.x<0.5 ? -1.0 : 1.0);
	float beat=phase*(kind==5 ? 9.0 : (kind==7 ? 18.0 : 14.0));
	float swing=sin(beat+limb*1.5708);
	if(pose==0){
		VERTEX.y-=sin(phase*2.3)*upper*0.65;
	}
	if(pose==1){
		// Alternating planted feet, knee bend, counter-swing of the shoulders.
		VERTEX.x+=swing*lower*(kind==7 ? 8.0 : 4.4);
		VERTEX.y-=max(0.0,swing)*lower*(kind==7 ? 7.0 : 4.0);
		VERTEX.x-=sin(beat)*upper*(kind==5 ? 3.6 : 1.6);
		VERTEX.y-=abs(sin(beat))*upper*(kind==7 ? 3.8 : 1.5);
	}
	if(kind==3 && (pose==2 || pose==3)){
		// Wing root stays attached; outer feathers fold and spread every stroke.
		float wing=(1.0-smoothstep(0.35,0.78,uv.x))*(1.0-smoothstep(0.1,0.72,uv.y));
		float flap=sin(phase*13.0);
		VERTEX.x+=wing*flap*16.0;
		VERTEX.y+=wing*(flap*23.0+7.0);
		VERTEX.x+=sin(phase*7.0)*lower*1.8;
	}
	if(pose==3 || pose==4){
		float wind=sin(clamp(progress/0.38,0.0,1.0)*1.5708);
		float strike=sin(clamp((progress-0.32)/0.68,0.0,1.0)*3.14159);
		float arm=smoothstep(0.38,0.9,uv.x)*(1.0-smoothstep(0.60,0.83,uv.y));
		float drive=strike*(kind==0 ? 18.0 : 12.0)-wind*4.5;
		VERTEX.x+=upper*drive*0.22+arm*drive;
		VERTEX.y+=arm*(kind==0 ? 0.0 : (wind*5.0-strike*9.0));
		VERTEX.x+=lower*strike*limb*1.3;
	}
	if(pose==5){
		float recoil=sin(progress*3.14159)*exp(-progress*1.2);
		VERTEX.x-=upper*recoil*9.0;
		VERTEX.y+=upper*recoil*3.0;
	}
	if(pose==6){
		VERTEX.x-=upper*progress*13.0;
		VERTEX.y+=upper*progress*12.0;
	}
}
void fragment(){
	vec4 tex=texture(TEXTURE,UV);
	tex.rgb=mix(tex.rgb,vec3(1.0,0.72,0.60),clamp(hurt*0.85,0.0,0.65));
	COLOR=tex*skin_tint;
}
