Shader "Custom/SingleTexture"
// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
{
	Properties
	{
		//_Color控制物体整体色调
		_Color("Color Tint", Color) = (1,1,1,1)
		//_MainTex 定义纹理 类型为2D 初值为white
		_MainTex("Main Tex", 2D) = "white"{}
		_Specular("Specular", Color) = (1,1,1,1)
		_Gloss("Gloss", Range(8.0, 256)) = 20
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
				sampler2D _MainTex;
				fixed4 _Specular;
				float _Gloss;
				//纹理名_ST，声明某个纹理的属性，得到缩放和平移值
				//_MainTex_ST.xy存储缩放值 unity界面中的Tilling
				//_MainTex_ST.zw存放偏移值 unity界面中的Offset
				float4 _MainTex_ST;


				struct a2v
				{
					float4 vertex : POSITION;
					float3 normal : NORMAL;
					//使用TEXCOORD0定义新变量texcoord，储存第一组纹理坐标
					float4 texcoord : TEXCOORD0;
				};

				struct v2f
				{
					float4 pos : SV_POSITION;
					float3 worldNormal : TEXCOORD0;
					float3 worldPos : TEXCOORD1;
					//使用TEXCOORD2定义uv,用于储存纹理坐标的变量，以便在片元着色器中使用该坐标进行纹理坐标采样
					float2 uv : TEXCOORD2;
				};

				v2f vert(a2v v)
				{
					v2f o;
					o.pos = UnityObjectToClipPos(v.vertex);
					o.worldNormal = normalize(UnityObjectToWorldNormal(v.normal));
					o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
					o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
					//缩放=v.texcoord.xy * _MainTex_ST.xy 平移= _MainTex_ST.zw
					//Unity中有内置宏TRANSFORM_TEX同样可以实现上述公式	o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
					return o;
				}

				fixed4 frag(v2f i) : SV_Target
				{
					fixed3 worldNormal = normalize(i.worldNormal);
					fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
					//对tex2D函数进行纹理采样，需要被采样的纹理，float2型的纹理坐标，反射率albedo
					/*
					* Function:tex2D
					* Type:fixed3
					* Input1:顶点纹理坐标
					* Input2:纹理名
					*/
					fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;

					fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
					fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));

					fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
					fixed3 halfDir = normalize(worldLightDir + viewDir);
					fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

					return fixed4(ambient + diffuse + specular, 1.0);
				}

				ENDCG
			}

		}
			Fallback "Specular"
}