Shader "ArmNomads/Standard"
{
	Properties
	{
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Main Texture", 2D) = "white" {}
		_HColor ("Highlight Color", Color) = (0.785,0.785,0.785,1.0)
		_SColor ("Shadow Color", Color) = (0.195,0.195,0.195,1.0)

		_RampThreshold ("Ramp Threshold", Range(0,1)) = 0.5
		_RampSmooth ("Ramp Smoothing", Range(0.01,1)) = 0.1

		[Toggle(EMISSION)] _Emission("Emission", Int) = 0
		[HideInInspector] _EmissionMap("Emission Map", 2D) = "white" {}
		[HideInInspector][HDR] _EmissionColor("Color", Color) = (0,0,0,1)


		[Toggle(SPECULAR)] _Specular("Specular", Int) = 0
		[Toggle(SPECULAR_STYLIZED)][HideInInspector] _SpecularStylized("Specular Stylized", Int) = 0
		[Toggle(SPECULAR_CRISP)][HideInInspector] _SpecularCrisp("Specular Crisp", Int) = 0
		[HideInInspector][HDR] _SpecularColor("Color", Color) = (1,1,1,1)
		[HideInInspector] _SpecularRoughness("Roughness", Range(0,1)) = 0
		[HideInInspector] _SpecularToonSize("Size", Range(0,1)) = 0
		[HideInInspector] _SpecularToonSmoothness("Smoothing", Range(0,1)) = 0
		[HideInInspector] _SpecGlossMap("Specular Texture", 2D) = "white" {}

		[Toggle(RIM_LIGHTING)] _RimLighting("Rim Lighting", Int) = 0
		[HideInInspector][HDR] _RimColor("Color", Color) = (1,1,1,1)
		[HideInInspector] _RimMin("Min", Range(0,1)) = 0
		[HideInInspector] _RimMax("Max", Range(0,1)) = 0
		[HideInInspector][Toggle(RIM_LIGHT_BASED)] _LightBased("Light Based", Float) = 0


		[Toggle(GRADIENT)] _Gradient("Gradient", Int) = 0
		[HideInInspector] _GradPos("Position", Float) = 0
		[HideInInspector] _GradSize("Size", Float) = 1
		[HideInInspector] _GradTopColor("Top Color", Color) = (1,1,1,1)
		[HideInInspector] _GradBottomColor("Bottom Color", Color) = (1,1,1,1)

		[Toggle(OVERLAY_TEXTURE)] _OverlayTexture("Overlay Texture", Int) = 0
		[HideInInspector][Toggle(OVERLAY_PROJECTION)] _OverlayProj("Overlay Projection", Int) = 0
		[HideInInspector] _ProjAngle("Projection Angle", Vector) = (0,0,0,0)
		[HideInInspector] _ProjScaleOffset("Scale and Offset", Vector) = (1,1,0,0)
		[HideInInspector] _OverlayTint("Tint", Color) = (1,1,1,1)
		[HideInInspector] _OverlayTex ("Texture", 2D) = "black" {}

		[Toggle(WORLD_SPACE_UV)] _WorldSpaceUV("World Space UV", Int) = 0
		[HideInInspector] _TriBlendOffset("Blend Offset", Range(0,0.5)) = 0
		[HideInInspector] _TriBlendExp("Blend Exponent", Range(1, 8)) = 2

		[Toggle(PLANE_CLIPPING)] _PlaneClipping("Plane Clipping", Int) = 0
		[HideInInspector]_PlanePosition("Plane Position", Vector) = (0,0,0,0)
		[HideInInspector]_PlaneNormal("Plane Normal", Vector) = (0,0,1,0)

		[Toggle(DISPLACEMENT)] _Displacement("Displacement", Int) = 0
		[HideInInspector] _DisplaceMap("Disp. Map", 2D) = "black" {}
		[HideInInspector] _DisplaceHeight("Height", Float) = 0
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "LightMode"="ForwardBase"}
		LOD 100
		Cull Off

		Pass
		{
			CGPROGRAM

			#include "ANStandard.cginc"

			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fog
			#pragma multi_compile_fwdbase
			#pragma shader_feature_local EMISSION
			#pragma shader_feature_local SPECULAR
			#pragma shader_feature_local SPECULAR_STYLIZED
			#pragma shader_feature_local SPECULAR_CRISP
			#pragma shader_feature_local RIM_LIGHTING
			#pragma shader_feature_local RIM_LIGHT_BASED
			#pragma shader_feature_local WORLD_SPACE_UV
			#pragma shader_feature_local OVERLAY_TEXTURE
			#pragma shader_feature_local OVERLAY_PROJECTION
			#pragma shader_feature_local GRADIENT
			#pragma shader_feature_local PLANE_CLIPPING
			#pragma shader_feature_local DISPLACEMENT

			ENDCG
		}

		Pass
		{
			Tags {"LightMode" = "ShadowCaster"}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_shadowcaster

			#pragma shader_feature_local PLANE_CLIPPING

			#include "UnityCG.cginc"

			struct v2f {
#if PLANE_CLIPPING
				float3 worldPos : TEXCOORD4;
#endif
				V2F_SHADOW_CASTER;
			};

			v2f vert(appdata_base v)
			{
				v2f o;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
#if PLANE_CLIPPING
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
#endif
				return o;
			}

#if PLANE_CLIPPING
			float3 _PlanePosition;
			float3 _PlaneNormal;
#endif

			float4 frag(v2f i, fixed facing : VFACE) : SV_Target
			{
#if PLANE_CLIPPING
				clip(dot((_PlanePosition - i.worldPos), _PlaneNormal));
#endif
				SHADOW_CASTER_FRAGMENT(i)
			}
			ENDCG
		}
	}
	Fallback "Standard"
	CustomEditor "ArmNomads.Shaders.ANStandardShaderGUI"
}
