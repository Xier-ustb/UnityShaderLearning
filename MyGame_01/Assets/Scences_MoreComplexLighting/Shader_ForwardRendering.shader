// Upgrade NOTE: replaced '_LightMatrix0' with 'unity_WorldToLight'
// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/Shader_ForwardRendering"
  {
	Properties
	{
		_Diffuse("Diffuse Color",Color)=(1,1,1,1)
		_Specular("Specular",Color)=(1,1,1,1)
		_Gloss("Gloss",Range(8.0,256))=20
	}
	SubShader
	{
		Tags{"RenderType"="Opaque"}
		Pass
		{
			Tags{"LightMode"="ForwardBase"}
			CGPROGRAM
			//#pragma multi_compile_fwdbase可以保证我们在Shader中使用光照衰减等
			//光照变量可以被正确赋值。这是不可缺少的
			#pragma multi_compile_fwdbase
			#pragma vertex vert
			#pragma fragment frag
			#include "Lighting.cginc"
			
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
			};
			
			v2f vert(a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos=mul(unity_ObjectToWorld,v.vertex).xyz;
				return o;
			}
			
			fixed4 frag(v2f i):SV_Target
			{
				fixed3 worldNormal = normalize(i.worldNormal);
				//得到平行光的方向
				fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				//计算了环境光
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				//_LightColor0可以得到平行光的强度和颜色
				fixed3 diffuse = _LightColor0.rgb*_Diffuse.rgb*max(0,dot(worldNormal,worldLightDir));
				fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
				fixed3 halfDir = normalize(worldLightDir + viewDir);
				fixed3 specular = _LightColor0.rgb*_Specular.rgb*pow(max(0,dot(worldNormal,halfDir)),_Gloss);
				//平行光没有衰减，故衰减值为0
				fixed atten = 1.0;
				return fixed4(ambient + (diffuse+specular)*atten,1.0);
			}
			ENDCG
		}
		
		//通常来说，Addtional Pass的光照处理和Base Pass的处理方式是一样的，因此我们只需要把
		//Base Pass的顶点和片元着色器代码复制到Additional Pass中，稍微修改一下即可。
		Pass
		{
			Tags{"LightMode"="ForwardAdd"}
			//开启和设置了混合模式
			//希望Additional Pass 计算得到的光照结果与之前的光照结果进行叠加。
			//没有使用Blend命令的话，Additional Pass会直接覆盖掉之前的光照结果
			//我们也可以选择其他Blend命令，如Blend SrcAlpha One
			Blend One One
			CGPROGRAM
			//这个指令保证我们再Additional Pass中访问正确的光照变量
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
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
			};
			
			v2f vert(a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
				return o;
			}
			
			fixed4 frag(v2f i):SV_Target
			{
				fixed3 worldNormal = normalize(i.worldNormal);
				//如果是平行光的话
				#ifdef USING_DIRECTIONAL_LIGHT
					fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				#else
					fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos.xyz);
				#endif
				
				fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb*max(0,dot(worldNormal,worldLightDir));
				
				fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz-i.worldPos.xyz);
				fixed3 halfDir = normalize(worldLightDir+viewDir);
				fixed3 specular = _LightColor0.rgb*_Specular.rgb*pow(max(0,dot(worldNormal,halfDir)),_Gloss);
				
				//如果是平行光的话
				#ifdef USING_DIRECTIONAL_LIGHT
					fixed atten = 1.0;
				#else
					//如果是点光源
					#if defined(POINT)
						float3 lightCoord = mul(unity_WorldToLight,float4(i.worldPos,1)).xyz;
						fixed atten = tex2D(_LightTexture0,dot(lightCoord,lightCoord).rr).UNITY_ATTEN_CHANNEL;
					//如果是聚光灯
					#elif defined(SPOT)
						float4 lightCoord = mul(unity_WorldToLight,float4(i.worldPos,1));
						fixed atten = (lightCoord.z > 0)*tex2D(_LightTexture0,lightCoord.xy/lightCoord.w+0.5).w*
							tex2D(_LightTextureB0,dot(lightCoord,lightCoord).rr).UNITY_ATTEN_CHANNEL;
					#else
						fixed atten = 1.0
					#endif
				#endif
				
				return fixed4((diffuse+specular)*atten,1.0);
			}
			
			ENDCG
		}
	}
	Fallback "Diffuse"
}