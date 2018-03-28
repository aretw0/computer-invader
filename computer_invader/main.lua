--[[

As funções de callback no LÖVE são chamadas por love.run para executar várias tarefas e são todas opcionais. No entanto, uma experiência de jogo repleta de recursos provavelmente utilizaria quase todos eles, portanto é sensato saber quais são.

Um callback (retorno de chamada), para aqueles novos para programação ou desconhecidos com o termo, é uma função que funciona de trás para frente em certo sentido. Em uma função regular como love.graphics.draw ou math.floor, você chama e LÖVE ou Lua faz alguma coisa. Um callback, por outro lado, é uma função que você codifica e LÖVE chama em determinados momentos. Isso facilita manter seu código organizado e otimizado.

Por exemplo, como o love.load só é chamado uma vez quando o jogo é iniciado pela primeira vez (antes de qualquer outro callback), é um ótimo lugar para colocar código que carrega o conteúdo do jogo e, de outra forma, "prepara as coisas".

]]


--[[
Essa função é chamada apenas uma vez, quando o jogo é iniciado, e normalmente é onde você carrega recursos, inicializa variáveis e defini configurações específicas. Todas essas coisas podem ser feitas em qualquer outro lugar também, mas fazê-las aqui significa que elas são feitas apenas uma vez, economizando muitos recursos do sistema.
]]
function love.load(arg)
  -- para vias de debugação, não utilizado ainda
  if arg and arg[#arg] == "-debug" then require("mobdebug").start() end
  
  -- criando fontes com estilos e tamanhos
  fontGame = love.graphics.newFont("space age.ttf", 20)
  fontWin = love.graphics.newFont("space age.ttf", 75)
  fontOver = love.graphics.newFont("DIRTYEGO.ttf", 75)
  
  -- criando imagens
  spaceBackground = love.graphics.newImage("space-background.png")
  spaceFloor = love.graphics.newImage("mars-water.jpg")
  enemyShip = love.graphics.newImage("enemy-600x600.png")
  heroShip = love.graphics.newImage("spaceship.png")  
  
  -- declaração da tabela game e suas variáveis
  game = {} 
  game.state = 0 -- 0 para inicio, 1 para em progresso, 2 para fim do jogo
  game.over = false -- Saber se o fim do jogo foi por perca
  
  hero = {} -- nova tabela para o herói
  -- x,y coordenadas do heroi
  hero.x = 360
  hero.y = 400
  hero.width = 30 -- largura do herói
  hero.height = 15 -- tamanho do herói
  hero.shots = {} -- tabela para contagem de tiros usados
  hero.image = heroShip -- atribuição de imagem
  hero.speed = 150 -- variável para velocidade
  hero.shotCount = 5 -- cartucho de tiros inicial
  
  -- variáveis do jogo
  time = 0 -- score de tempo
  wave = 0 -- número da onda
  waveSize = 3 -- tamanho da onda
  velEnemy = 0.15 -- velocidade da onda
  score = 0 -- score de pontos
  enemies = {} -- declaração da tabela de inimigos
  genEnemies() -- função para gerar inimigos
  
end

--Essa função é chamada sempre que uma tecla do teclado é liberada e recebe a chave liberada.
function love.keyreleased(key)
  -- na v0.9.2 e mais recentes espaço é representado pelo caractere ' ', entao checo pelos dois
  if (key == " " or key == "space") then
    -- espaço foi apertado, chega se o jogo ta rolando, se sim, cria tiros na tabela de tiros (hero.shots)
    if game.state == 1 then
       shoot()
    end
  end
  if key == "return" then
    -- enter foi apertado, se o jogo não começou inicializa-se
    if game.state == 0 then
      game.state = 1
    end
  end
  if key == "r" then
    -- r foi apertado se o jogo terminou de alguma forma reseta o jogo chamando love.load manualmente
    if game.over or game.state == 2 then
      love.load()
    end
  end
end

--[[
Esta função é chamada continuamente e provavelmente será onde a maioria de sua matemática é feita. 'dt' significa "tempo delta" e é a quantidade de segundos desde a última vez que esta função foi chamada (que geralmente é um valor pequeno como 0.025714)
]]
function love.update(dt)
  -- se o jogo não acabou por perca
  if not game.over then
    -- se jogo ta rolando
    if game.state == 1 then
      -- conte o tempo
      time = time + dt
    else 
      return -- se não acabe aqui o fluxo da função
    end
  else
    return -- aqui também
  end
  
  --[[ Ações para nosso herói
  
    Se a tecla da esquerda/direita esta apertada faça o calculo de deslocação de seus eixo x usando a velocidade dele e a variação de tempo.
  ]]
  if love.keyboard.isDown("left") then
    hero.x = hero.x - hero.speed*dt 
  elseif love.keyboard.isDown("right") then
    hero.x = hero.x + hero.speed*dt
  end

-- variáveis locais para regra de remoção de balas e inimigos
  local remEnemy = {}
  local remShot = {}

  -- Atualiza os tiros, for para cada tiro que o herói tiver dado
  for i,v in ipairs(hero.shots) do
    -- move eles para cima, mexendo no eixo x através da variação do tempo * 100
    v.y = v.y - dt * 100

-- marca tiros que não estão mais na tela para remoção, o eixo y é de cima para baixo, menor que 0 significa acima da janela
    if v.y < 0 then
      table.insert(remShot, i)
    end

    -- checa as colisões entre tiros e inimigos, para cada inimigo faz
    for ii,vv in ipairs(enemies) do
      -- função para chegar a colisão, x,y do tiro (for acima) com o x,y, largura e altura do inimigo do for atual 
      if CheckCollision(v.x,v.y,2,5,vv.x,vv.y,vv.width,vv.height) then
        score = score + 10 -- se houve colisão incremente score
        -- marca o inimigo para remoção
        table.insert(remEnemy, ii)
        -- marca o tiro para remoção
        table.insert(remShot, i)
      end
    end
  end
  -- remove os inimigos marcados
  for i,v in ipairs(remEnemy) do
    table.remove(enemies, v)
  end
  -- remove os tiros marcados
  for i,v in ipairs(remShot) do
    table.remove(hero.shots, v)
  end

  -- atualiza os inimigos restantes
  for i,v in ipairs(enemies) do
    -- calculo para a queda deles
    v.y = v.y + (time * velEnemy)

    -- checa a colisão com o chão
    if v.y > 410 then
      -- PERDEU!!!
      game.over = true
    end
  end
  
  -- para saber se venceu, ainda existem inimigos?
  if (#enemies == 0) then
    -- se não, estamos na ultima onda?
    if wave < 3 then
      -- se não de respawn nos inimigos
      genEnemies()
    else
      -- se era a ultima onda você venceu
      game.state = 2
    end
  end
end
--[[
love.draw é onde todo o desenho acontece e se você chamar qualquer um dos love.graphics.draw fora desta função não terá nenhum efeito. Esta função também é chamada continuamente, então tenha em mente que se você alterar a fonte / cor / modo / etc no final da função, isso terá um efeito sobre as coisas no início da função.
]]
function love.draw()
  -- colocando a imagem de background
  love.graphics.draw(spaceBackground,0,0,0,0.5,0.5)
  -- colocando a imagem do chão
  love.graphics.draw(spaceFloor,0,465,0,1,1)
  
  -- desenhando o herói
--  love.graphics.setColor(255,255,255,255)
  love.graphics.draw(hero.image,hero.x,hero.y,0,0.2,0.2)

  -- desenhando qualquer tiro que ele tenha dado
  love.graphics.setColor(255,255,255,255)
  for i,v in ipairs(hero.shots) do
    love.graphics.rectangle("fill", v.x, v.y, 3, 5)
  end
  
  -- se o game começou desenha os inimigos
  if not (game.state == 0) then
    for i,v in ipairs(enemies) do
      love.graphics.draw(v.image,v.x,v.y,0,0.1,0.1)
    end
  end
  
  -- Se o jogo começou, mostremos as informações
  if (not (game.state == 0)) then 
    love.graphics.setColor(255,255,255,255)
    love.graphics.setFont(fontGame)
    love.graphics.print(("Onda %d \nTempo %d \nPontos %d"):format(wave,time,score), 10, 10)
  end
  
  -- se o jogo ta no menu mostre a mensage
  if (game.state == 0) then 
    love.graphics.setColor(255,255,255,255)
    love.graphics.setFont(fontGame)
    love.graphics.print("Presione Enter para começar", 170, 200)
    love.graphics.print("Barra de espaço (Atirar)", 170, 290)
    love.graphics.print("Esquerda / Direita (Controle da Nave)", 170, 320)
    love.graphics.print("R (Reiniciar)", 170, 370)
  end
  
  -- Mensagens
  
  -- se o jogo acabou por perca mostre o game over
  if game.over then
    love.graphics.setColor(255,255,255,255)
    love.graphics.setFont(fontOver)
    love.graphics.print(("GAME OVER"), 300, 200)
  end
  -- se jogo chegou ao fim sem perca significa que você venceu, mostre a mensagem de vitória
  if game.state == 2 then
    love.graphics.setColor(255,255,255,255)
    love.graphics.setFont(fontWin)
    love.graphics.print("YOU WIN", 200, 200)
  end

end

-- função para inserir tiror na tabela hero.shots
function shoot()
  if #hero.shots >= hero.shotCount then return end -- se você chegar ao limite de tiror não gera mais tiros
  local shot = {}
  shot.x = (hero.x+hero.width/2)+9
  -- calculo para sair a bala no meio da nave o 9 é importante
  shot.y = hero.y
  table.insert(hero.shots, shot)
end

-- função para gerar inimigos
function genEnemies()
  for i=0,waveSize do
    local enemy = {}
    enemy.image = enemyShip
    enemy.width = 50
    enemy.height = 50
    enemy.x = i * (enemy.width + 60) + 100
    enemy.y = enemy.height + 5
    table.insert(enemies, enemy)
  end
  waveSize = waveSize + 1
  wave = wave + 1
  velEnemy = velEnemy + 0.005
  hero.shotCount = hero.shotCount + 3
  hero.speed = hero.speed + 50
end

-- Funçao de detecção de colisão
-- Checa se um a colidiu com um b
-- w e h significa largura e altura
function CheckCollision(ax1,ay1,aw,ah, bx1,by1,bw,bh)
  local ax2,ay2,bx2,by2 = ax1 + aw, ay1 + ah, bx1 + bw, by1 + bh
  return ax1 < bx2 and ax2 > bx1 and ay1 < by2 and ay2 > by1
end