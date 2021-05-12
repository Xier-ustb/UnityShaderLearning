// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/Specular_PixelLevel"
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

        //color在0-1之间用float
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
            float3 worldNormal : TEXCOORD0;
            float3 worldPos : TEXCOORD1;
        };

        v2f vert(a2v v)
        {
            /*************坐标计算******************/
            v2f o;
            //transform the vertex object space to clip space
            o.pos = UnityObjectToClipPos(v.vertex);
            //transform the normal from object space to world space
            o.worldNormal = normalize(mul(v.normal,(float3x3)unity_WorldToObject));
            //transform the vertex from object space o world space
            o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
       
            return o;
        }

        fixed4 frag(v2f i) :SV_Target
        {
            //get ambient term
            fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
            
            fixed3 worldNormal = normalize(i.worldNormal);
            fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
            //compute diffuse term
            fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLightDir));
            //get the reflect dirction in world space，unity中reflect的入射方向是光源指向交点，所以需要取反
            fixed3 reflectDir = normalize(reflect(-worldLightDir, worldNormal));
            //get the view dirction in world space，_WorldSpaceCameraPos.xyz得到世界空间的摄像机位置
            fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
            //compute specular term
            fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(reflectDir, viewDir)), _Gloss);
            return fixed4(ambient + diffuse + specular,1.0f);
        }
        ENDCG
    }

    }
        Fallback "Specular"
}