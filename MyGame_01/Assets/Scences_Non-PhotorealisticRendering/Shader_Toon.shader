Shader "Custom/Shader_Toon"
{
    Properties
    {
        _Color ("ColorTint", Color) = (1,1,1,1)
        _MainTex ("MainTex", 2D) = "white" {}
        _Ramp ("RampTexture", 2D) = "white"{}
        _Specular ("Specular", Color) = (1,1,1,1)
        _SpecularScale ("SpecularScale", Range(0,0.1)) = 0.03
        _Outline ("Outline",Range(0,1)) = 0.015
        _OutlineColor ("OutlineColor", Color) = (0,0,0,1)
    }
    SubShader 
    {  
        Tags { "RenderType"="Opaque" "Queue"="Geometry"}  
        //这个Pass只渲染背面的三角面片  
        Pass 
        {  
            NAME "OUTLINE"  
            //剔除正面  
            Cull Front  

            CGPROGRAM  

            #pragma vertex vert  
            #pragma fragment frag  
            #include "UnityCG.cginc"  

            float _Outline;  
            fixed4 _OutlineColor;  

            struct a2v 
            {  
                float4 vertex : POSITION;  
                float3 normal : NORMAL;  
            };   

            struct v2f 
            {  
                float4 pos : SV_POSITION;  
            };  

            v2f vert (a2v v) 
            {  
                v2f o;  
                //顶点和法线变换到视角空间
                float4 pos = mul(UNITY_MATRIX_MV, v.vertex);   
                float3 normal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);   
                //设置法线的 z 分量对其归一化后再将顶点沿其方向扩张
                normal.z = -0.5;  
                pos = pos + float4(normalize(normal), 0) * _Outline;  
                //顶点从视角空间变换到裁剪空间
                o.pos = mul(UNITY_MATRIX_P, pos);  

                return o;  
            }  

            float4 frag(v2f i) : SV_Target 
            {   
                return float4(_OutlineColor.rgb, 1);                 
            }  

            ENDCG  
        }  
        //只渲染正面  
        Pass 
        {  
            Tags { "LightMode"="ForwardBase" }  

            Cull Back  

            CGPROGRAM  

            #pragma vertex vert  
            #pragma fragment frag  
            #pragma multi_compile_fwdbase  
            #include "UnityCG.cginc"  
            #include "Lighting.cginc"  
            #include "AutoLight.cginc"  
            #include "UnityShaderVariables.cginc"  

            fixed4 _Color;  
            sampler2D _MainTex;  
            float4 _MainTex_ST;  
            sampler2D _Ramp;  
            fixed4 _Specular;  
            fixed _SpecularScale;  

            struct a2v 
            {  
                float4 vertex : POSITION;  
                float3 normal : NORMAL;  
                float4 texcoord : TEXCOORD0;  
                float4 tangent : TANGENT;  
            };   

            struct v2f 
            {  
                float4 pos : POSITION;  
                float2 uv : TEXCOORD0;  
                float3 worldNormal : TEXCOORD1;  
                float3 worldPos : TEXCOORD2;  
                SHADOW_COORDS(3)  
            };  

            v2f vert (a2v v) 
            {  
                v2f o;  
                //世界空间下的法线方向和顶点位置
                o.pos = UnityObjectToClipPos( v.vertex);  
                o.uv = TRANSFORM_TEX (v.texcoord, _MainTex);  
                o.worldNormal  = UnityObjectToWorldNormal(v.normal);  
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;  

                //计算阴影所需的各个变量
                TRANSFER_SHADOW(o);  

                return o;  
            }  

            float4 frag(v2f i) : SV_Target 
            {  

                //光照模型中需要的各个方向矢量 
                fixed3 worldNormal = normalize(i.worldNormal);  
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));  
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));  
                fixed3 worldHalfDir = normalize(worldLightDir + worldViewDir);  

                fixed4 c = tex2D (_MainTex, i.uv);  
                fixed3 albedo = c.rgb * _Color.rgb;  

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;  

                //阴影值
                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);  

                fixed diff =  dot(worldNormal, worldLightDir);  
                diff = (diff * 0.5 + 0.5) * atten;  

                fixed3 diffuse = _LightColor0.rgb * albedo * tex2D(_Ramp, float2(diff, diff)).rgb;  

                //高光区域的边界进行抗锯齿处理
                fixed spec = dot(worldNormal, worldHalfDir);  
                fixed w = fwidth(spec) * 2.0;  
                fixed3 specular = _Specular.rgb * lerp(0, 1, smoothstep(-w, w, spec + _SpecularScale - 1)) * step(0.0001, _SpecularScale);  

                return fixed4(ambient + diffuse + specular, 1.0);  
            }  

            ENDCG  
        }  
    }  
    FallBack "Diffuse"  
}  

