Shader "Custom/Shader_AlphaBlending_ZWrite"
{
	Properties 
    {
		_Color ("ColorTint", Color) = (1,1,1,1)
		_MainTex ("MainTex", 2D) = "white" {}
		_AlphaScale("AlphaScale", Range(0,1)) = 1
	}
	SubShader
    {
		Tags { 	"Queue"="Transparent"
				"IgnoreProjector" = "True"
				"RenderType" = "Transparent" 
				}
        
        //Extra pass that renders to depth buffer only
        pass
        {
            ZWrite On
            ColorMask 0
        }

		Pass
        {
			Tags{"LightMode" = "ForwardBase"}
			ZWrite Off//关闭深度写入
			Blend SrcAlpha OneMinusSrcAlpha
			//开启混合，并设置混合因子。片元着色器产生的颜色是源颜色，源颜色的混合因子设为SrcAlpha，目标颜色是已经存在于颜色缓冲中的颜色，混合因子设为OneMinusSrcAlpha
			//颜色缓冲 = (源颜色*SrcFactor + 目标颜色*DstFactor)
 
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Lighting.cginc"
 
			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _AlphaScale;
 
			struct a2v
            {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
			};
 
			struct v2f
            {
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				float2 uv : TESSFACTOR2;
			};
 
			v2f vert(a2v v)
            {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = UnityObjectToWorldDir(v.vertex).xyz;
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
 
				return o;
			}
 
			fixed4 frag(v2f i) : SV_Target
            {
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldPos = normalize(i.worldPos);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
 
				fixed4 texColor = tex2D(_MainTex, i.uv);
				fixed3 albedo = texColor.rgb * _Color.rgb;
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));
				
				return fixed4(ambient+diffuse, texColor.a * _AlphaScale);
			}
 
			ENDCG
 
		}
		
	}
	FallBack "Transparent/VertexLit"
}