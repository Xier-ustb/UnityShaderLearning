// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Custom/Specular_VertexLevel"
{
    Properties
    {
        _Diffuse("Diffuse", Color) = (1,1,1,1)
        _Specular("Specular", Color) = (1,1,1,1)
        _Gloss("Gloss", Range(8.0, 256)) = 20

    }
        SubShader
    {
        Pass
        {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"

            //color在0-1之间用fixed
            fixed4 _Diffuse;
            fixed4 _Specular;
            //Gloss范围大需要用float
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                fixed3 color : COLOR;
            };

            v2f vert(a2v v)
            {
                v2f o;
                //transform the vertex object space to clip space
                o.pos = UnityObjectToClipPos(v.vertex);
                //get ambient term
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                //transform the normal from object space to world space
                fixed3 worldNormal = normalize(mul(v.normal,(float3x3)unity_WorldToObject));
                //get the light dirction in world space
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                /****************以上与Diffuse操作相同************************/

                //compute diffuse term
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLightDir));
                //get the reflect dirction in world space，unity中reflect的入射方向是光源指向交点，所以需要取反
                fixed3 reflectDir = normalize(reflect(-worldLightDir, worldNormal));
                //get the view dirction in world space，_WorldSpaceCameraPos.xyz得到世界空间的摄像机位置
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld, v.vertex).xyz);
                //compute specular term
                //pow 求幂  pow(x, y)=x^y
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(reflectDir, viewDir)), _Gloss);
                o.color = ambient + diffuse + specular;
                return o;
            }

            fixed4 frag(v2f i) :SV_Target
            {
                return fixed4(i.color,1.0f);
            }
            ENDCG
        }
        
    }
        Fallback "Specular"
}
