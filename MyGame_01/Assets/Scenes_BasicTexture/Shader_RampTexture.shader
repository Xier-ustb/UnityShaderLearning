Shader "Custom/RampTexture"
{
    Properties
    {
        _Color("Color Tint",Color) = (1,1,1,1)
        _RampTex("Ramp Tex",2D) = "white"{}
        _Specular("Specular",Color) = (1,1,1,1)
        _Gloss("Gloss",Range(8.0,256)) = 20
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
            sampler2D _RampTex;
            float4 _RampTex_ST;        
            float _Gloss;
 
        struct a2v
        {
            float4 vertex:POSITION;
            float3 worldNormal:NORMAL;
            float4 texcoord:TEXCOORD0;
        };
 
        struct v2f
        {
            float4 pos :SV_POSITION;
            float3 worldNormal:TEXCOORD0;
            float3 worldPos:TEXCOORD1;
            float2 uv:TEXCOORD2;
        };
 
        v2f vert(a2v v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.worldNormal = UnityObjectToWorldNormal(v.worldNormal);
            o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
            //采用内置宏TRANSFORM_TEX来计算平铺和偏移后的纹理坐标
            o.uv = TRANSFORM_TEX(v.texcoord, _RampTex);
            return o;
        }
 
        fixed4 frag(v2f i) : SV_Target
        {
            fixed3 worldNormal = normalize(i.worldNormal);
            fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
            fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

            /*************use the texture to sample the diffuse color****************/
            //使用halfLambert来构建一个纹理坐标，并使用这个坐标对渐变纹理_RampTex进行采样
            fixed halfLambert = 0.5 * dot(worldNormal, worldLightDir) + 0.5;
            fixed3 diffuseColor = tex2D(_RampTex, fixed2(halfLambert,halfLambert)).rgb * _Color.rgb;
            //fixed2(halfLambert,halfLambert)纹理坐标(u,v)
            /*
             * Function: tex2D(sampler2D tex, float2 s)
             * Type: float4
             * Input: sampler2D tex 被采样的纹理, float2 s 纹理坐标
             * Output: 计算得到的纹素值
            */
            fixed3 diffuse = _LightColor0.rgb * diffuseColor;
 
            fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
            fixed3 halfDir = normalize(worldLightDir + viewDir);
            fixed3 specular = _LightColor0.rgb * _Specular * pow(max(0, dot(worldNormal, halfDir)), _Gloss);
 
            return fixed4(ambient + diffuse + specular, 1.0);
        }
            ENDCG
        }
        }
            Fallback "Specular"
}
