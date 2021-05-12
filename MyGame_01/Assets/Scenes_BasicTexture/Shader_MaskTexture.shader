Shader "Custom/MaskTexture"
{
    Properties 
    {
        _Color ("ColorTint", Color) = (1,1,1,1)
        _MainTex ("MainTex", 2D) = "white" {}
        _BumpMap("NormalMap", 2D) = "bump"{}
        _BumpScale("BumpScale", Float) = 1.0
        _Specular("Specular", Color) = (1,1,1,1)
        _SpecularMask("SpecularMask", 2D) = "white"{}
        _SpecularScale("SpecularScale", Float) = 1.0
        _Gloss ("Gloss", Range(8,256)) = 20
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
            float _Gloss;
            //主纹理
            sampler2D _MainTex;
            float4 _MainTex_ST;
            //凹凸(法线)纹理
            sampler2D _BumpMap;
            float _BumpScale;
            //遮罩纹理
            sampler2D _SpecularMask;
            float _SpecularScale;
 
 
            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 texcoord : TEXCOORD0;
            };
 
            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 lightDir : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
            };
 
            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                TANGENT_SPACE_ROTATION;
                o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex));
                o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex));
                return o;
            }
 
            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 tangentLightDir = normalize(i.lightDir);
                fixed3 tangentViewDir = normalize(i.viewDir);
 
                fixed3 tangentNormal = UnpackNormal(tex2D(_BumpMap, i.uv));
                /*
                * Function: UnpackNormal
                * Input: fixed4 packednormal
                * Output: 对法线纹理进行采样。以UnpackNormal方法来说，它最主要的也就是packednormal.xyz * 2 – 1
                */
                tangentNormal.xy = tangentNormal.xy * _BumpScale;
                tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));
 
                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(tangentNormal, tangentLightDir));
 
                fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);
                fixed3 specularMask = tex2D(_SpecularMask, i.uv).r * _SpecularScale;
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(tangentNormal, halfDir)), _Gloss) * specularMask;
 
                return fixed4(ambient + diffuse + specular, 1.0f);
 
            }
        
            ENDCG
        }
    }
    FallBack "Specular"
}
