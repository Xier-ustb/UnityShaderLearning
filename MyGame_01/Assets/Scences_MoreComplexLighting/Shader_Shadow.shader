// Upgrade NOTE: replaced '_LightMatrix0' with 'unity_WorldToLight'
// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/Shader_Shadow"
{
    Properties
    {
		_Diffuse("Diffuse",Color)=(1,1,1,1)
		_Specular("Specular",Color)=(1,1,1,1)
		_Gloss("Gloss",Range(8.0,256)) = 20
	}
	SubShader
    {
		// Tags{"LightMode"="ShaderCaster"}
		Pass{
			Tags{"LightMode"="ForwardBase"}
			CGPROGRAM
			#pragma multi_compile_fwdbase
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			
			fixed4 _Diffuse;
			fixed4 _Specular;
			float _Gloss;
			
			struct a2v
            {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};
			
			struct v2f
            {
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				//作用是声明一个用于阴影纹理采样的坐标。
				//这个宏的参数需要是下一个可用的插值寄存器的索引值
				SHADOW_COORDS(2)
			};
			
			v2f vert(a2v v)
            {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
				//用于在顶点着色器中计算上一步中声明的阴影纹理坐标
				TRANSFER_SHADOW(o);
				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target
            {
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				fixed3 diffuse = _LightColor0.rgb*_Diffuse.rgb*max(0,dot(worldNormal,worldLightDir));
				fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz-i.worldPos.xyz);
				fixed3 halfDir = normalize(worldLightDir+viewDir);
				fixed3 specular = _LightColor0.rgb*_Specular.rgb*pow(max(0,dot(worldNormal,halfDir)),_Gloss);
				fixed atten = 1.0;
				//计算阴影值
				fixed shadow = SHADOW_ATTENUATION(i);
				return fixed4(ambient+(diffuse+specular)*atten*shadow,1.0);
			}
			ENDCG
		}
		Pass{
			Tags{"LightMode"="ForwardAdd"}
			
			Blend One One
			
			CGPROGRAM
			#pragma multi_compile_fwdadd
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			
			fixed4 _Diffuse;
			fixed4 _Specular;
			float _Gloss;
			
			struct a2v
            {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};
			
			struct v2f
            {
				float4 position : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
			};
			
			v2f vert(a2v v)
            {
				v2f o;
				o.position = UnityObjectToClipPos(v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
				return o;
			}
			
			fixed4 frag(v2f i):SV_Target
            {
				fixed3 worldNormal = normalize(i.worldNormal);
				#ifdef USING_DIRECTIONAL_LIGHT
					fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				#else
					fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos.xyz);
				#endif
				
				fixed3 diffuse = _LightColor0.rgb*_Diffuse.rgb*max(0,dot(worldNormal,worldLightDir));
				fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
				fixed3 halfDir = normalize(worldLightDir+viewDir);
				fixed3 specular = _LightColor0.rgb*_Specular.rgb*pow(max(0,dot(worldNormal,halfDir)),_Gloss);
				
				#ifdef USING_DIRECTIONAL_LIGHT
					fixed atten = 1.0;
				#else
					float3 lightCoord = mul(unity_WorldToLight,float4(i.worldPos,1)).xyz;
					fixed atten = tex2D(_LightTexture0,dot(lightCoord,lightCoord).rr).UNITY_ATTEN_CHANNEL;
				#endif
				
				return fixed4((diffuse+specular)*atten,1.0);
			}
			ENDCG
		}
	}
	Fallback "Specular"
}