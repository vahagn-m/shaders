using UnityEditor;
using UnityEngine;

namespace ArmNomads.Shaders
{
    public class ANStandardShaderGUI : ShaderGUI
    {
        private static readonly string[] SPECULAR_TYPES = { "Standard", "Stylized", "Crisp" };

        private Material targetMat;

        private MaterialProperty emissionMapProp;
        private MaterialProperty emissionColorProp;
        private MaterialProperty specColorProp;
        private MaterialProperty specRoughnessProp;
        private MaterialProperty specSizeProp;
        private MaterialProperty specSmoothnessProp;
        private MaterialProperty specTextureProp;
        private MaterialProperty rimColorProp;
        private MaterialProperty rimMinProp;
        private MaterialProperty rimMaxProp;
        private MaterialProperty rimLightBasedProp;
        private MaterialProperty gradientPosProp;
        private MaterialProperty gradientSizeProp;
        private MaterialProperty gradientTopColorProp;
        private MaterialProperty gradientBottomColorProp;
        private MaterialProperty triBlendOffsetProp;
        private MaterialProperty triBlendExpProp;
        private MaterialProperty overlayProjProp;
        private MaterialProperty projAngleProp;
        private MaterialProperty projScaleOffsetProp;
        private MaterialProperty overlayTintProp;
        private MaterialProperty overlayTexProp;
        private MaterialProperty clipPlanePosProp;
        private MaterialProperty clipPlaneNormalProp;
        private MaterialProperty clipSectionEmmisiveProp;
        private MaterialProperty clipSectionColorProp;
        private MaterialProperty displacementMapProp;
        private MaterialProperty displacementHeightProp;

        private int selectedSpecularType;

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            targetMat = materialEditor.target as Material;

            emissionMapProp = FindProperty("_EmissionMap", properties);
            emissionColorProp = FindProperty("_EmissionColor", properties);

            specColorProp = FindProperty("_SpecularColor", properties);
            specRoughnessProp = FindProperty("_SpecularRoughness", properties);
            specSizeProp = FindProperty("_SpecularToonSize", properties);
            specSmoothnessProp = FindProperty("_SpecularToonSmoothness", properties);
            specTextureProp = FindProperty("_SpecGlossMap", properties);

            rimColorProp = FindProperty("_RimColor", properties);
            rimMinProp = FindProperty("_RimMin", properties);
            rimMaxProp = FindProperty("_RimMax", properties);
            rimLightBasedProp = FindProperty("_LightBased", properties);

            gradientPosProp = FindProperty("_GradPos", properties);
            gradientSizeProp = FindProperty("_GradSize", properties);
            gradientTopColorProp = FindProperty("_GradTopColor", properties);
            gradientBottomColorProp = FindProperty("_GradBottomColor", properties);

            triBlendOffsetProp = FindProperty("_TriBlendOffset", properties);
            triBlendExpProp = FindProperty("_TriBlendExp", properties);

            overlayProjProp = FindProperty("_OverlayProj", properties);
            projAngleProp = FindProperty("_ProjAngle", properties);
            projScaleOffsetProp = FindProperty("_ProjScaleOffset", properties);
            overlayTintProp = FindProperty("_OverlayTint", properties);
            overlayTexProp = FindProperty("_OverlayTex", properties);

            clipPlanePosProp = FindProperty("_PlanePosition", properties);
            clipPlaneNormalProp = FindProperty("_PlaneNormal", properties);
            clipSectionEmmisiveProp = FindProperty("_ClipSectionEmmisive", properties);
            clipSectionColorProp = FindProperty("_ClipSectionColor", properties);

            displacementMapProp = FindProperty("_DisplaceMap", properties);
            displacementHeightProp = FindProperty("_DisplaceHeight", properties);

            foreach (var property in properties)
            {
                if (((int)property.flags & (int)MaterialProperty.PropFlags.HideInInspector) > 0)
                    continue;
                if (property.name.Equals("_Emission"))
                {
                    DrawEmissionProperties(property, materialEditor);
                }
                else if (property.name.Equals("_Specular"))
                {
                    DrawSpecularProperties(property, materialEditor);
                }
                else if (property.name.Equals("_WorldSpaceUV"))
                {
                    DrawWorldSpaceUVProperties(property, materialEditor);
                }
                else if (property.name.Equals("_OverlayTexture"))
                {
                    DrawOverlayTextureProperties(property, materialEditor);
                }
                else if (property.name.Equals("_Gradient"))
                {
                    DrawGradientProperties(property, materialEditor);
                }
                else if (property.name.Equals("_PlaneClipping"))
                {
                    DrawPlaneClippingProperties(property, materialEditor);
                }
                else if (property.name.Equals("_Displacement"))
                {
                    DrawDisplacementProperties(property, materialEditor);
                }
                else if (property.name.Equals("_RimLighting"))
                {
                    DrawRimLightingProperties(property, materialEditor);
                }
                else
                {
                    materialEditor.ShaderProperty(property, property.displayName);
                }
            }
            EditorGUILayout.Space();
            materialEditor.EnableInstancingField();
            materialEditor.RenderQueueField();
        }


        private void DrawWorldSpaceUVProperties(MaterialProperty toggleProp, MaterialEditor materialEditor)
        {
            using (var v = new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
            {
                DrawShaderKeywordToggle(toggleProp, "WORLD_SPACE_UV");
                if (toggleProp.floatValue <= 0)
                    return;
                ++EditorGUI.indentLevel;
                materialEditor.ShaderProperty(triBlendOffsetProp, triBlendOffsetProp.displayName);
                materialEditor.ShaderProperty(triBlendExpProp, triBlendExpProp.displayName);
                --EditorGUI.indentLevel;
            }
        }

        private void DrawRimLightingProperties(MaterialProperty toggleProp, MaterialEditor materialEditor)
        {
            using (var v = new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
            {
                DrawShaderKeywordToggle(toggleProp, "RIM_LIGHTING");
                if (toggleProp.floatValue <= 0)
                    return;
                ++EditorGUI.indentLevel;
                materialEditor.ShaderProperty(rimColorProp, rimColorProp.displayName);
                materialEditor.ShaderProperty(rimMinProp, rimMinProp.displayName);
                materialEditor.ShaderProperty(rimMaxProp, rimMaxProp.displayName);
                materialEditor.ShaderProperty(rimLightBasedProp, rimLightBasedProp.displayName);
                --EditorGUI.indentLevel;
            }
        }

        private void DrawEmissionProperties(MaterialProperty toggleProp, MaterialEditor materialEditor)
        {
            using (var v = new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
            {
                DrawShaderKeywordToggle(toggleProp, "EMISSION");
                if (toggleProp.floatValue <= 0)
                    return;
                ++EditorGUI.indentLevel;
                materialEditor.ShaderProperty(emissionMapProp, emissionMapProp.displayName);
                materialEditor.ShaderProperty(emissionColorProp, emissionColorProp.displayName);
                --EditorGUI.indentLevel;
            }
        }

        private void DrawSpecularProperties(MaterialProperty toggleProp, MaterialEditor materialEditor)
        {
            using (var v = new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
            {
                DrawShaderKeywordToggle(toggleProp, "SPECULAR");
                if (toggleProp.floatValue <= 0)
                    return;
                ++EditorGUI.indentLevel;
                if (targetMat.IsKeywordEnabled("SPECULAR_STYLIZED") || targetMat.IsKeywordEnabled("SPECULAR_CRISP"))
                    selectedSpecularType = targetMat.IsKeywordEnabled("SPECULAR_STYLIZED") ? 1 : 2;
                else
                    selectedSpecularType = 0;
                selectedSpecularType = EditorGUILayout.Popup("Type", selectedSpecularType, SPECULAR_TYPES);
                materialEditor.ShaderProperty(specColorProp, specColorProp.displayName);
                if (selectedSpecularType == 0)
                {
                    targetMat.DisableKeyword("SPECULAR_STYLIZED"); targetMat.DisableKeyword("SPECULAR_CRISP");
                    materialEditor.ShaderProperty(specRoughnessProp, specRoughnessProp.displayName);
                }
                else
                {
                    materialEditor.ShaderProperty(specSizeProp, specSizeProp.displayName);
                    if (selectedSpecularType == 1)
                    {
                        targetMat.EnableKeyword("SPECULAR_STYLIZED"); targetMat.DisableKeyword("SPECULAR_CRISP");
                        materialEditor.ShaderProperty(specSmoothnessProp, specSmoothnessProp.displayName);
                    }
                    else
                    {
                        targetMat.EnableKeyword("SPECULAR_CRISP");
                        targetMat.DisableKeyword("SPECULAR_STYLIZED");
                    }
                }
                materialEditor.TexturePropertySingleLine(new GUIContent(specTextureProp.displayName), specTextureProp);
                --EditorGUI.indentLevel;
            }
        }

        private void DrawOverlayTextureProperties(MaterialProperty toggleProp, MaterialEditor materialEditor)
        {
            using (var v1 = new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
            {
                DrawShaderKeywordToggle(toggleProp, "OVERLAY_TEXTURE");
                if (toggleProp.floatValue <= 0)
                    return;
                ++EditorGUI.indentLevel;
                materialEditor.ShaderProperty(overlayTintProp, overlayTintProp.displayName);
                materialEditor.TexturePropertySingleLine(new GUIContent(overlayTexProp.displayName), overlayTexProp);
                using (var v2 = new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
                {
                    DrawShaderKeywordToggle(overlayProjProp, "OVERLAY_PROJECTION");
                    if (overlayProjProp.floatValue > 0)
                    {
                        EditorGUILayout.LabelField(projAngleProp.displayName);
                        EditorGUILayout.BeginHorizontal();
                        Vector4 anglePropValue = projAngleProp.vectorValue;
                        anglePropValue.x = EditorGUILayout.Slider(anglePropValue.x, -1f, 1f);
                        anglePropValue.y = EditorGUILayout.Slider(anglePropValue.y, -1f, 1f);
                        projAngleProp.vectorValue = anglePropValue;
                        EditorGUILayout.EndHorizontal();
                        materialEditor.ShaderProperty(projScaleOffsetProp, projScaleOffsetProp.displayName);
                    }
                }
                --EditorGUI.indentLevel;
            }
        }

        private void DrawGradientProperties(MaterialProperty toggleProp, MaterialEditor materialEditor)
        {
            using (var v = new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
            {
                DrawShaderKeywordToggle(toggleProp, "GRADIENT");
                if (toggleProp.floatValue <= 0)
                    return;
                ++EditorGUI.indentLevel;
                materialEditor.ShaderProperty(gradientPosProp, gradientPosProp.displayName);
                materialEditor.ShaderProperty(gradientSizeProp, gradientSizeProp.displayName);
                materialEditor.ShaderProperty(gradientTopColorProp, gradientTopColorProp.displayName);
                materialEditor.ShaderProperty(gradientBottomColorProp, gradientBottomColorProp.displayName);
                --EditorGUI.indentLevel;
            }
        }

        private void DrawPlaneClippingProperties(MaterialProperty toggleProp, MaterialEditor materialEditor)
        {
            using (var v = new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
            {
                DrawShaderKeywordToggle(toggleProp, "PLANE_CLIPPING");
                if (toggleProp.floatValue <= 0)
                    return;
                ++EditorGUI.indentLevel;
                materialEditor.ShaderProperty(clipSectionColorProp, clipSectionColorProp.displayName);
                materialEditor.ShaderProperty(clipSectionEmmisiveProp, clipSectionEmmisiveProp.displayName);
                materialEditor.ShaderProperty(clipPlanePosProp, clipPlanePosProp.displayName);
                materialEditor.ShaderProperty(clipPlaneNormalProp, clipPlaneNormalProp.displayName);
                --EditorGUI.indentLevel;
            }
        }

        private void DrawDisplacementProperties(MaterialProperty toggleProp, MaterialEditor materialEditor)
        {
            using (var v = new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
            {
                DrawShaderKeywordToggle(toggleProp, "DISPLACEMENT");
                if (toggleProp.floatValue <= 0)
                    return;
                ++EditorGUI.indentLevel;
                materialEditor.TexturePropertySingleLine(new GUIContent(displacementMapProp.displayName), displacementMapProp);
                materialEditor.ShaderProperty(displacementHeightProp, displacementHeightProp.displayName);
                --EditorGUI.indentLevel;
            }
        }

        private void DrawShaderKeywordToggle(MaterialProperty toggleProp, string keyword)
        {
            FontStyle originalFontStyle = EditorStyles.label.fontStyle;
            EditorStyles.label.fontStyle = toggleProp.floatValue > 0 ? FontStyle.Bold : FontStyle.Normal;
            toggleProp.floatValue = EditorGUILayout.Toggle(toggleProp.displayName, toggleProp.floatValue > 0) ? 1f : 0f;
            if (toggleProp.floatValue > 0)
                targetMat.EnableKeyword(keyword);
            else
                targetMat.DisableKeyword(keyword);
            EditorStyles.label.fontStyle = originalFontStyle;
        }
    }
}