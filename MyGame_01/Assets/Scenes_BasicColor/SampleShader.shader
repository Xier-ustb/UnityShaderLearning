Shader "Custom/SampleShader"
{
 Properties{
        //属性
    }
    SubShader{
        //针对显卡A的SubShader
        Pass{
            //设置渲染状态和标签
 
            //开始CG代码片段
            CGPROGRAM
            //该代码片段的编译指令
            #pragma vertex vert
            #pragma fragment frag
 
            //CG代码写在这里
            ENDCG
            //其他设置
        }
        //其他需要的Pass
    }
    SubShader{
        //针对显卡B的SubShader
    }
 
    //上述SubShader都失败后用于回调的Unity Shader
    Fallback "VertexLit"
}

