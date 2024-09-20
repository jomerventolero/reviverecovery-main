<script setup lang="ts">
import { useThemeConfiguration } from '@/composables/use-theme-configuration';
import { rulesToCssVars, useTheme } from '@directus/themes';
import { computed } from 'vue';

const props = defineProps<{
	darkMode: boolean;
	theme: string | null;
}>();

const { themeLightOverrides, themeDarkOverrides } = useThemeConfiguration();

const { theme } = useTheme(props.darkMode, props.theme, props.theme, themeLightOverrides, themeDarkOverrides);

const localVars = computed(() => {
	return rulesToCssVars(theme.value.rules);
});
</script>

<template>
	
</template>

<style scoped lang="scss">
.theme-preview {
	svg {
		width: 100%;
		border: 1px solid var(--theme--border-color-subdued);
		border-radius: 4px;
	}
}
</style>
