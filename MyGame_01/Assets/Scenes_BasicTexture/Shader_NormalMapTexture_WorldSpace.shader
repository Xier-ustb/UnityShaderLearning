// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/NormalMapTexture_WorldSpace"
{
	Properties
	{
		_Color("Color Tint", Color) = (1.0,1.0,1.0,1.0)
		_MainTex("Main Tex", 2D) = "white"{}
		_Gloss("Gloss", Range(8.0, 256)) = 20
		_Specular("Specular", Color) = (1.0,1.0,1.0,1.0)
		_BumpMap("Normal Map", 2D) = "bump" {}
		_BumpScale("Bump Scale", Float) = 1.0 //控制凹凸程度
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

				fixed4 _Color;
				fixed4 _Specular;

				sampler2D _MainTex;
				float4 _MainTex_ST;

				sampler2D _BumpMap;
				float4 _BumpMap_ST;
				
				float _Gloss;
				float _BumpScale;

				struct a2v 
				{
					float4 vertex : POSITION;
					float3 normal : NORMAL;
					float4 texcoord : TEXCOORD0;
					//用TANGENT语义定义float4类型的变量 tangent,储存顶点的切线方向
					//不同于normal的类型是float3，要使用到tangent.w来决定切线空间的副切线的方向
					float4 tangent : TANGENT;
				};

				struct v2f 
				{
					float4 pos : SV_POSITION;
					float4 uv : TEXCOORD0;
					float4 TtoW0 : TEXCOORD1;
					float4 TtoW1 : TEXCOORD2;
					float4 TtoW2 : TEXCOORD3;
				};

				v2f vert(a2v v) 
				{
					v2f o;
					o.pos = UnityObjectToClipPos(v.vertex);
					//缩放 = v.texcoord.xy * _MainTex_ST.xy + 平移 = _MainTex_ST.zw
					o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
					o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

					float3 worldPos = UnityObjectToClipPos(v.vertex).xyz;
					fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
					fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
					fixed3 worldBinormal = cross(worldNormal,worldTangent) *  v.tangent.w;
					
					o.TtoW0 = float4(worldTangent.x,worldBinormal.x,worldNormal.x,worldPos.x);
					o.TtoW1 = float4(worldTangent.y,worldBinormal.y,worldNormal.y,worldPos.y);
					o.TtoW2 = float4(worldTangent.z,worldBinormal.z,worldNormal.z,worldPos.z);
					return o;
				}

				fixed4 frag(v2f i) : SV_Target
				{
					float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);
					fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
					fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));

					fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));
					bump.xy *= _BumpScale;
					bump.z = sqrt(1.0 - saturate(dot(bump.xy, bump.xy)));
					bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));

					fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
					fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
					fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(bump, lightDir));
					fixed3 halfDir = normalize(lightDir + viewDir);
					fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(bump, halfDir)), _Gloss);
					return fixed4(ambient + diffuse + specular, 1.0);

				}


				ENDCG
			}

		}
			FallBack "Specular"
}
