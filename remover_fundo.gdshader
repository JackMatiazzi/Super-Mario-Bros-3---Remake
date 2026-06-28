shader_type canvas_item;

// ==========================================
// 1. CONFIGURAÇÃO PARA REMOVER COR (Transparência)
// ==========================================
uniform vec4 cor_para_remover : source_color = vec4(0.0, 1.0, 0.0, 1.0); // O Verde padrão
uniform float tolerancia_remover : hint_range(0.0, 1.0) = 0.1;

// ==========================================
// 2. CONFIGURAÇÃO PARA MUDAR COR (Ex: Mudar para Preto)
// ==========================================
uniform vec4 cor_para_alterar : source_color = vec4(1.0, 0.0, 0.0, 1.0); // A cor que você quer que suma
uniform vec4 nova_cor : source_color = vec4(0.0, 0.0, 0.0, 1.0); // A cor que vai entrar no lugar (Preto)
uniform float tolerancia_alterar : hint_range(0.0, 1.0) = 0.1;

// ==========================================
// CONFIGURAÇÃO GERAL
// ==========================================
uniform float suavidade : hint_range(0.0, 1.0) = 0.05;

void fragment() {
    // Pega a cor atual do pixel na imagem
    vec4 cor_atual = texture(TEXTURE, UV);
    
    // --- PASSO 1: ALTERAR A COR ---
    // Calcula a distância para ver se o pixel atual é a cor que queremos alterar
    float dist_alterar = distance(cor_atual.rgb, cor_para_alterar.rgb);
    
    // Cria a máscara: vai dar 0 se for a cor alvo, e 1 se for o resto da imagem
    float mascara_alterar = smoothstep(tolerancia_alterar, tolerancia_alterar + suavidade, dist_alterar);
    
    // Mistura a nova_cor (preto) com a cor original do pixel.
    cor_atual.rgb = mix(nova_cor.rgb, cor_atual.rgb, mascara_alterar);

    // --- PASSO 2: APLICAR TRANSPARÊNCIA ---
    // Calcula a distância para ver se o pixel é a cor que queremos deixar transparente
    float dist_remover = distance(cor_atual.rgb, cor_para_remover.rgb);
    
    // Cria a máscara do Alpha (transparência)
    float alpha = smoothstep(tolerancia_remover, tolerancia_remover + suavidade, dist_remover);
    
    // Aplica o resultado final combinando as cores alteradas com o recorte transparente
    COLOR = vec4(cor_atual.rgb, cor_atual.a * alpha);
}