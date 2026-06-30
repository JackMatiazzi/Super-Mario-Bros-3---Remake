shader_type canvas_item;

// Controla o fechamento (0.0 = totalmente aberto, 1.0 = totalmente preto)
uniform float progresso : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec2 uv = UV;
    
    // Calcula a distância do centro formando um formato retangular/quadrado
    float dist_x = abs(uv.x - 0.5) * 2.0;
    float dist_y = abs(uv.y - 0.5) * 2.0;
    
    // Se a distância for maior que a área permitida, pinta de preto
    if (max(dist_x, dist_y) > (1.0 - progresso)) {
        COLOR = vec4(0.0, 0.0, 0.0, 1.0); // Preto opaco
    } else {
        COLOR = vec4(0.0, 0.0, 0.0, 0.0); // Transparente (mostra o jogo)
    }
}