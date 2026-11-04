Shader "Granja/Agua corriente"
{
    Properties
    {
        _ColorAgua ("Color del agua", Color) = (0.075, 0.22, 0.20, 0.82)
        _ColorEspuma ("Color de la espuma", Color) = (0.79, 0.86, 0.79, 1)
        [Normal] _Ondas ("Ondas", 2D) = "bump" {}
        _Velocidad ("Velocidad de la corriente", Range(0, 3)) = 0.85
        _FuerzaOndas ("Fuerza de las ondas", Range(0, 1)) = 0.2
        _Espuma ("Espuma", Range(0, 1)) = 0.4
        [Toggle] _Rio ("Es un rio", Float) = 1
        _CentroLago ("Centro del lago (X, Z)", Vector) = (82, 82, 0, 0)
        _SemiejesLago ("Semiejes y radio del lago", Vector) = (23, 17, 0.925, 0)
    }
    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "Queue"="Transparent" }
        Pass
        {
            Name "Agua"
            Tags { "LightMode"="UniversalForward" }
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            Cull Off
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag
            #pragma multi_compile_fog
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            TEXTURE2D(_Ondas); SAMPLER(sampler_Ondas);
            CBUFFER_START(UnityPerMaterial)
                half4 _ColorAgua, _ColorEspuma;
                float4 _Ondas_ST;
                float4 _CentroLago, _SemiejesLago;
                float _Velocidad, _FuerzaOndas, _Espuma, _Rio;
            CBUFFER_END
            struct Entrada { float4 posicion:POSITION; float3 normal:NORMAL; float4 tangente:TANGENT; float2 uv:TEXCOORD0; half4 color:COLOR; };
            struct Salida { float4 posicion:SV_POSITION; float3 mundo:TEXCOORD0; float3 normal:TEXCOORD1; float4 tangente:TEXCOORD2; float2 uv:TEXCOORD3; half4 color:COLOR; half niebla:TEXCOORD4; };

            Salida Vert(Entrada v)
            {
                Salida o;
                VertexPositionInputs p=GetVertexPositionInputs(v.posicion.xyz);
                VertexNormalInputs n=GetVertexNormalInputs(v.normal,v.tangente);
                o.posicion=p.positionCS; o.mundo=p.positionWS; o.normal=n.normalWS;
                o.tangente=float4(n.tangentWS,v.tangente.w*GetOddNegativeScale());
                o.uv=v.uv; o.color=v.color; o.niebla=ComputeFogFactor(p.positionCS.z);
                return o;
            }
            float Ruido(float2 p)
            {
                float2 i=floor(p), f=frac(p); f=f*f*(3-2*f);
                float a=frac(sin(dot(i,float2(127.1,311.7)))*43758.5453);
                float b=frac(sin(dot(i+float2(1,0),float2(127.1,311.7)))*43758.5453);
                float c=frac(sin(dot(i+float2(0,1),float2(127.1,311.7)))*43758.5453);
                float d=frac(sin(dot(i+1,float2(127.1,311.7)))*43758.5453);
                return lerp(lerp(a,b,f.x),lerp(c,d,f.x),f.y);
            }
            half4 Frag(Salida i):SV_Target
            {
                // El rio se recorta donde comienza el lago para no superponer agua transparente.
                float2 q=(i.mundo.xz-_CentroLago.xy)/_SemiejesLago.xy;
                if (_Rio>.5)
                {
                    // Interseccion con los mismos 120 lados de la malla del lago.
                    float paso=6.28318530718/120;
                    float a0=floor(atan2(q.y,q.x)/paso)*paso, a1=a0+paso;
                    float r0=_SemiejesLago.z*(1+.055*sin(a0*5)+.03*sin(a0*9));
                    float r1=_SemiejesLago.z*(1+.055*sin(a1*5)+.03*sin(a1*9));
                    float2 p0=float2(cos(a0),sin(a0))*r0;
                    float2 lado=float2(cos(a1),sin(a1))*r1-p0;
                    float2 direccion=normalize(q);
                    float radio=(p0.x*lado.y-p0.y*lado.x)/(direccion.x*lado.y-direccion.y*lado.x);
                    clip(length(q)-radio+.0003);
                }

                // Ondas comunes en coordenadas del mundo: coinciden a ambos lados de la union.
                float tiempo=_Time.y*_Velocidad;
                float2 comun=i.mundo.xz*.055;
                float2 comunGirado=float2(comun.x*.8-comun.y*.6,comun.x*.6+comun.y*.8)*1.63;
                float3 ondaA=UnpackNormalScale(SAMPLE_TEXTURE2D(_Ondas,sampler_Ondas,comun+float2(_Time.y*.018,-_Time.y*.025)),_FuerzaOndas);
                float3 ondaB=UnpackNormalScale(SAMPLE_TEXTURE2D(_Ondas,sampler_Ondas,comunGirado+float2(-_Time.y*.013,_Time.y*.017)),_FuerzaOndas*.65);
                float3 normalComun=normalize(i.normal+float3(ondaA.x+ondaB.x,0,ondaA.y+ondaB.y));
                float corriente=_Rio*smoothstep(12,36,distance(i.mundo.xz,float2(64,91)));

                // La corriente pierde fuerza progresivamente al entrar al estanque.
                float2 uv=float2(i.uv.x*1.7,i.uv.y*0.23);
                float2 avance=float2(tiempo*0.035,-tiempo*0.32);
                float3 a=UnpackNormalScale(SAMPLE_TEXTURE2D(_Ondas,sampler_Ondas,uv+avance),_FuerzaOndas);
                float3 b=UnpackNormalScale(SAMPLE_TEXTURE2D(_Ondas,sampler_Ondas,uv*1.73+float2(-avance.x, avance.y*.76)),_FuerzaOndas*.65);
                float3 nTS=normalize(float3(a.xy+b.xy,a.z*b.z));
                float3 t=normalize(i.tangente.xyz), n=normalize(i.normal);
                float3 binormal=cross(n,t)*i.tangente.w;
                n=normalize(t*nTS.x+binormal*nTS.y+n*nTS.z);
                n=normalize(lerp(normalComun,n,corriente*.7));
                float3 vista=SafeNormalize(GetWorldSpaceViewDir(i.mundo));
                Light sol=GetMainLight(TransformWorldToShadowCoord(i.mundo));
                float difusa=saturate(dot(n,sol.direction));
                float fresnel=pow(1-saturate(dot(n,vista)),4);
                half3 reflejo=GlossyEnvironmentReflection(reflect(-vista,n),i.mundo,.19h,1.0h);
                half3 color=_ColorAgua.rgb*(SampleSH(n)+sol.color*(.25+.55*difusa)*sol.shadowAttenuation);
                color=lerp(color,reflejo,.12+fresnel*.62);
                float brillo=pow(saturate(dot(n,normalize(sol.direction+vista))),110)*.32;
                color+=sol.color*brillo*sol.shadowAttenuation;
                float2 flujo=float2(i.uv.x*7,i.uv.y*.8-tiempo*1.4);
                float ruido=Ruido(flujo);
                float bandas=sin(i.uv.y*4.7-tiempo*6+ruido*7+sin(i.uv.x*27)*2.3);
                float espuma=smoothstep(-.1,.75,bandas)*smoothstep(.66,.9,ruido);
                espuma*=_Espuma*corriente*(.10+i.color.r*1.8);
                espuma+=i.color.g*corriente*smoothstep(.35,.8,ruido)*.5;
                color=lerp(color,_ColorEspuma.rgb,saturate(espuma));
                color=MixFog(color,i.niebla);
                float borde=lerp(1,smoothstep(0,.1,i.uv.x)*(1-smoothstep(.9,1,i.uv.x)),_Rio);
                return half4(color,_ColorAgua.a*borde*lerp(1,i.color.a,_Rio));
            }
            ENDHLSL
        }
    }
}
