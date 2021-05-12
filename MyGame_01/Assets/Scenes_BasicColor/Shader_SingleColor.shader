// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/Chapter5_simpleshader"
{
    SubShader
    {
        Pass
        {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            /*
            命名规则 
            #pragma vertex name
            #pragma fragment name
            作用：告诉编译器哪个函数包含顶点/片元shader的代码
            */

            float4 vert(float4 v : POSITION) : SV_POSITION
            {
                return UnityObjectToClipPos(v);
            }
            /*
            * Function: 顶点着色器 逐顶点执行
            * Type: float4
            * Input: v
            * Output: v在剪裁空间中的位置
            *
            * UNITY_MATRIX_MVP/UnityObjectToClipPos(v)
            * 当前的模型观察投影矩阵，用于将顶点/方向矢量从模型空间变换到剪裁空间
            * 
            * SV_POSITION
            * 裁剪空间中的顶点坐标，结构体中必须包含用该语义修饰的变量，等同于DirectX 9中的POSITION，最好用SV_POSITION
            */

            fixed4 frag() : SV_Target
            {
                return fixed4(1,1,1,1);
            }

            ENDCG
        }
    }
}
