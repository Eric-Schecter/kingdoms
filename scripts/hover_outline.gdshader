shader_type canvas_item;
uniform bool highlighted=false;
uniform vec4 highlight_color : source_color=vec4(1.0,0.83,0.4,1.0);
varying vec4 unit_tint;
void vertex(){unit_tint=COLOR;}
void fragment(){
 vec4 base=texture(TEXTURE,UV);
 if(highlighted && base.a<0.2){
  vec2 d=TEXTURE_PIXEL_SIZE*5.0;
  float edge=0.0;
  for(int y=-1;y<=1;y++) for(int x=-1;x<=1;x++) edge=max(edge,texture(TEXTURE,UV+vec2(float(x),float(y))*d).a);
  COLOR=vec4(highlight_color.rgb,edge*highlight_color.a);
 }else{COLOR=base; if(highlighted){COLOR.rgb=mix(base.rgb,highlight_color.rgb,0.16);}}
 COLOR*=unit_tint;
}
