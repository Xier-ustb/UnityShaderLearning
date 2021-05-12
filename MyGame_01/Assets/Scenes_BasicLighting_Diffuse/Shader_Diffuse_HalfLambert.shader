Shader "Custom/Diffuse_HalfLambert"//漫反射-半兰伯特光照
{
	Properties
	{
		_Diffuse("Diffuse", Color) = (1,1,1,1)

	}
		SubShader
	{
			Pass
		{
			Tags{"LightMode" = "ForwardBase"}

		CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Lighting.cginc"
			fixed4 _Diffuse;

			struct a2v
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				fixed3 worldNormal : TEXCOORD0;
			};

			//vertex shader不需要计算光照模型，只需传递法线
			v2f vert(a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				//顶点着色器的基本任务，transform the vertex from object space to clip space
				o.worldNormal = normalize(mul(v.normal,(float3x3)unity_WorldToObject));
				//逆转置或转置逆

				return o;
			}
			//fragment shader计算光照模型
			fixed4 frag(v2f i) : SV_Target
			{
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				fixed halfLambert = dot(worldNormal, worldLightDir) * 0.5 + 0.5;
				fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * halfLambert;
				
				fixed3 color = ambient + diffuse;
				return fixed4(color, 1.0f);
			}
		ENDCG

		}

	}
		FallBack "Diffuse"
}

