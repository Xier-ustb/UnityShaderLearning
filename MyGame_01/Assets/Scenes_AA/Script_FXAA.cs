using System.Collections;
using System.Collections.Generic;
using UnityEngine;
//FXAA抗锯齿后处理

[ExecuteInEditMode]
public class Script_FXAA : Script_PostEffectBase
{
    /// <summary>
    /// 像素点采样的范围
    /// </summary>
    [Range(0.1f, 1.0f)]
    public float size = 0.5f;
    /// <summary>
    /// 索贝尔算子采样范围
    /// </summary>
    [Range(0.1f, 1.0f)]
    public float sobelSize = 0.5f;
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        _Material.SetFloat("_Size", size);
        _Material.SetFloat("_SobelSize", sobelSize);
        Graphics.Blit(source, destination, _Material);
    }
}


