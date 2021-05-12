Shader "Custom/Chapter6_testshader_01"//漫反射-逐顶点光照
{
	Properties
	{
		_Diffuse("Diffuse", Color) = (1,1,1,1)
		//Diffuse's type is Color,default value is white
	}
		SubShader
	{
			Pass// Vertex/Fragment shader 代码需要写在Pass语义块中
		{
				Tags{"LightMode" = "ForwardBase"}
				/* LightMode标签是Pass标签中的一种，用于定义该Pass在Unity的光照流水线中的角色
				* 指明光照模式为 ForwardBaes
				*/
			CGPROGRAM
			//定义顶点/片元着色器vert frag
			#pragma vertex vert
			#pragma fragment frag
			//使用unity内置变量
			#include "Lighting.cginc"
			//声明_Diffuse以使用在properties中定义的属性
			fixed4 _Diffuse;

			struct a2v // define input struct
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				//引入法线,逐顶点光照要在每个顶点上进行线性插值来计算得到像素光照
			};

			struct v2f // define output struct
			{
				float4 pos : SV_POSITION;
				fixed3 color : COLOR;//将顶点着色器中计算得到的光照颜色传给片元着色器 
			};

			v2f vert(a2v v) 
			{
				v2f o;
				//顶点着色器的基本任务，transform the vertex from object space to clip space
				o.pos = UnityObjectToClipPos(v.vertex);
				//得到环境光 get ambient term
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

				/*********************计算漫反射*****************************/
				/*计算漫反射公式：Cdiffuse = (Clight · Mdiffuse)max(0,n·l)
				* n是表面法线，l是指向光源的《单位矢量》，Mdiffuse是材质的漫反射颜色，Clight是光源颜色和强度信息
				* 现在，有①漫反射颜色 _Diffuse ②顶点法线v.normal 还需要知道 Clight 和 l
				* unity内置变量LightColor0访问该Pass处理的光源颜色和强度信息
				* 光源方向由_WorldSpaceLightPos0得到
				*/

				//transfrom the normal from object to world space
				fixed3 worldNormal = normalize(mul(v.normal,(float3x3)unity_WorldToObject));
				//get the light direction in world space
				fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
				//compute diffuse term，unity内置函数dot点乘 cross叉乘
				//当想把颜色值规范到0~1之间时，使用saturate函数
				//saturate(x)的作用是如果x取值小于0，则返回值为0。如果x取值大于1，则返回值为1。若x在0到1之间，则直接返回x的值.
				fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLight));

				o.color = ambient + diffuse;
				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target
			{
				return fixed4(i.color, 1.0f);
			}
			ENDCG
			}

	}
		FallBack "Diffuse"
}

