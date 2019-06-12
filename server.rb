#!/usr/bin/env ruby -w
require "socket"

class Server
  def initialize(ip, port)
    @server = TCPServer.open(ip,port)
    @lockClientes = Mutex.new
    @lockDedos = Mutex.new
    @lockPuntos = Mutex.new
    @lockRespuestas = Mutex.new
    @connections = Hash.new
    @clients = Hash.new
    @dedos = Hash.new
    @puntos = Hash.new
    @respuestas = Hash.new
    @connections[:server] = @server
    @connections[:clients] = @clients
    @connections[:dedos]=@dedos
    @connections[:puntos]=@puntos
    @connections[:respuestas]=@respuestas

    run
    contarClientes
    @contar.join
  end

  def contarDedos
    total = 0
    @connections[:respuestas].each do |nombre, dedos|
      total += dedos
    end
    return total
  end

  def encontrar_ganador_ronda
    total = contarDedos
    ganadoresRonda = []
    @connections[:respuestas].each do |nombre,respuesta|
      if respuesta == total
        ganadoresRonda.append(nombre)
      end
    end
    return ganadoresRonda
  end

  def get_ganador
    ganadores = []
    @connections[:puntos].each do |nombre,puntos|
      if puntos == 3
        ganadores.append(nombre)
      end
    end
    return ganadores
  end

  def contarClientes
    contador = 0
    @connections[:clients].each do |nombre, cliente|
      contador += 1
    end
    return contador
  end

  def run
    loop{
        Thread.start(@server.accept) do | client |
          begin
            client.puts "Ingrese su nombre de usuario"
            nick_name = client.gets.chomp.to_sym
            @connections[:clients].each do |other_name, other_client|
              if nick_name == other_name || client == other_client
                client.puts "Ese nombre ya existe porfavor ingrese otro"
                Thread.kill(self)
              end
            end
            @connections[:clients][nick_name]=client
            @connections[:puntos][nick_name]=0
            client.puts "Esperando jugadores..."
            jugar_partida(nick_name, client)
            client.close()
          rescue
            @connections[:clients].delete(nick_name)
            @connections[:dedos].delete(nick_name)
            @connections[:respuestas].delete(nick_name)
            @connections[:puntos].delete(nick_name)
          end
        end
    }.join
  end

  def jugar_partida(usuario, cliente)
    numeroJugadoresInicial = contarClientes
    @connections[:clients].each do |nombre, clienteAux|
      clienteAux.puts "Hay #{numeroJugadoresInicial} jugadores conectados"
    end
    loop{
      cliente.puts "Ingrese el numero de dedos a jugar"
      numDedos = cliente.gets.chomp
      @connections[:dedos][usuario] = numDedos.to_i
      cliente.puts "Ingrese el numero total de dedos que crea que hay en juego"
      respuesta = cliente.gets.chomp
      @connections[:respuestas][usuario] = respuesta.to_i

      ganadoresRonda = encontrar_ganador_ronda
      if ganadoresRonda.include? (usuario)
        cliente.puts "Acertaste!"
        @connections[:puntos][usuario] += 1
      else
        cliente.puts "Ups, fallaste"
      end
      ganadoresPartida = get_ganador
      unless ganadoresPartida.size == 0
        if ganadoresPartida.include? (usuario)
          cliente.puts "Ganaste!"
        else
          cliente.puts "Perdiste"
        end
        completado = true
      end
      if completado
        break
      end
    }
  end
end

Server.new("localhost", 65432)
