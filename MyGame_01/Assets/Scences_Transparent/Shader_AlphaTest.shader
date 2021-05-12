Shader "Custom/Shader_AlphaTest"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
        _MainTex("Maint Tex", 2D) = "white"{}
        _Cutoff("Alpha Cutoff", Range(0, 1)) = 0.5 // 注意，FallBack中 Transparent/Cutout/VertexLit 计算透明度时，使用了 _Cutoff 属性
    }
    SubShader
    {
        // 通常，使用了透明度测试的 Shader 都应该在SubShader 中设置这三个标签
        // "Queue"="AlphaTest" 开启透明度测试
        // "RenderType"="TransparentCutout" 可以让Unity把这个shader归入到提前定义的组（这里就是TransparentCutout组），
        // 以指明该shader是一个使用了透明测试的Shader。RenderType标签通常被用于着色器替换功能。
        // "IgnoreProjector"="True" 这个shader忽略投影器（Projectors）的影响。
        Tags { "Queue"="AlphaTest" 
                "RenderType"="TransparentCutout" 
                "IgnoreProjector"="True"
                }
        LOD 200
        Pass
        {
            Tags{"LightMode"="ForwardBase" }

            CGPROGRAM
            #pragma vertex vert 
            #pragma fragment frag 
            #include "Lighting.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Cutoff;

            struct a2v
            {
                float4 vertex : POSITION;
                float4 texcoord : TEXCOORD0;
                float3 normal : NORMAL;
            };
            struct v2f
            {
                float4 pos:SV_POSITION;
                float3 worldNormal:TEXCOORD0;
                float3 worldPos:TEXCOORD1;
                float2 uv:TEXCOORD2;
                

            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

             	fixed4 texColor = tex2D(_MainTex, i.uv);
                clip(texColor.a - _Cutoff); // 当 texColor.a - _Cutoff 为负时，舍弃该片元的输出，该片元产生完全透明的效果
                /*
                *=   if (texColor.a - _Cutoff) < 0
                *   {
                *       discard;
                *   }
                */
                fixed3 albedo = texColor.rgb * _Color.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0,dot(worldNormal, worldLightDir));
                return fixed4(ambient + diffuse, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Transparent/Cutout/VertexLit"
}
