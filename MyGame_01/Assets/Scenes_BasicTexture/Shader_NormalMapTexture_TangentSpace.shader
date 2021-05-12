Shader "Custom/NormalMapTexture"
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
					float3 lightDir : TEXCOORD1;//注意TEXCOORD是float2/float4
					float3 viewDir : TEXCOORD2;
				};

				v2f vert(a2v v) 
				{
					v2f o;
					o.pos = UnityObjectToClipPos(v.vertex);
					//缩放 = v.texcoord.xy * _MainTex_ST.xy + 平移 = _MainTex_ST.zw
					o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
					o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

					/*************compute the binormal*****************/
					//I traditional masure
					//float3 bionormal = cross(normalize(v.normal), normalize(v.tangent.xyz)) * v.tangent.w;	//w值决定叉乘的方向
					//construct a matrix which transform vertors from object space to tangent space
					//float3x3 rotation = float3x3(v.tangent.xyz, bionormal, v.normal);
					//II use macro
					TANGENT_SPACE_ROTATION;
					o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;
					o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;

					return o;
				}

				fixed4 frag(v2f i) : SV_Target
				{
					fixed3 tangentLightDir = normalize(i.lightDir);
					fixed3 tangentViewDir = normalize(i.viewDir);

					fixed4 packedNormal = tex2D(_BumpMap, i.uv.zw);//图，纹理坐标
					fixed3 tangentNormal;
					//if the texture is not marked as "Normal map"
					tangentNormal.xy = (packedNormal.xy*2-1)*_BumpScale;
					tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));//计算z分量
					//or marked as "Normal Map", use the built-in function
					//tangentNormal = UnpackNormal(packedNormal);
					//tangentNormal.xy *= _BumpScale;
					//tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

					fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
					fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
					fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(tangentNormal, tangentLightDir));
					fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);
					fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(tangentNormal, halfDir)), _Gloss);
					return fixed4(ambient + diffuse + specular, 1.0);

				}


				ENDCG
			}

		}
			FallBack "Specular"
}