library(shiny)
library(shinyjs)
library(tablerDash)
library(shinyWidgets)
library(shinyEffects)
library(pushbar)
library(shinyMons)
library(waiter)

source("pokeNames.R")

# main data
pokeMain <- readRDS("pokeMain")
pokeDetails <- readRDS("pokeDetails")

# subdata from main
pokeLocations <- readRDS("pokeLocations")
pokeMoves <- readRDS("pokeMoves")
pokeTypes <- readRDS("pokeTypes")
pokeEvolutions <- readRDS("pokeEvolutions")
pokeAttacks <- readRDS("pokeAttacks")
pokeEdges <- readRDS("pokeEdges")
pokeGroups <- readRDS("pokeGroups")

# pokemon sprites
pokeSprites <- vapply(
  seq_along(pokeNames),
  FUN = function(i) {
    pokeMain[[i]]$sprites$front_default
  },
  FUN.VALUE = character(1)
)

# shiny app code
shiny::shinyApp(
  ui = tablerDashPage(
    enable_preloader = TRUE,
    loading_duration = 4,
    navbar = tablerDashNav(
      id = "mymenu",
      src = "https://www.ssbwiki.com/images/9/9c/Master_Ball_Origin.png",
      navMenu = tablerNavMenu(
        tablerNavMenuItem(
          tabName = "PokeInfo",
          icon = "home",
          "PokeInfo"
        ),
      ),

      pokeInputUi(id = "input"),

      tablerDropdown(
        tablerDropdownItem(
          title = NULL,
          href = "https://pokeapi.co",
          url = "https://pokeapi.co/static/logo-6221638601ef7fa7c835eae08ef67a16.png",
          status = "danger",
          date = NULL,
          "This app use pokeApi by Paul Hallet and PokéAPI contributors."
        )
      )
    ),
    footer = tablerDashFooter(
      copyrights = "Disclaimer: this app is purely intended for learning purpose. @David Granjon, 2019"
    ),
    title = "Gotta Catch'Em (Almost) All",
    body = tablerDashBody(

      # load pushbar dependencies
      pushbar_deps(),
      # laad the waiter dependencies
      use_waiter(),
      # load shinyjs
      useShinyjs(),

      # custom jquery to hide some inputs based on the selected tag
      # actually tablerDash would need a custom input/output binding
      # to solve this issue once for all
      tags$head(
        tags$script(
          "$(function () {
            $('#mymenu .nav-item a').click(function(){
              var tab = $(this).attr('id');
              if (tab == 'tab-PokeInfo' || tab == 'tab-PokeList') {
                $('#input-pokeChoice').show();
              } else {
                $('#input-pokeChoice').hide();
              }
            });
           });"
        ),

      ),

      # custom shinyWidgets skins
      chooseSliderSkin("Round"),

      # use shinyEffects
      setShadow(class = "galleryCard"),
      setZoom(class = "galleryCard"),

      tablerTabItems(
        tablerTabItem(
          tabName = h1("PokeInfo"),
          fluidRow(
            column(
              width = 4,
              pokeInfosUi(id = "infos"),
              pokeTypeUi(id = "types"),
              pokeEvolveUi(id = "evol")
            ),
            column(
              width = 8,
              pokeStatsUi(id = "stats"),
              pokeMoveUi(id = "moves"),
              pokeLocationUi(id = "location")
            )
          )
        )
      )
    )
  ),
  server = function(input, output, session) {

    # Network module: network stores a potential selected node in the
    # network and pass it to the pickerInput function in the main
    # module to update its value
    network <- callModule(
      module = pokeNetwork,
      id = "network",
      mainData = pokeMain,
      details = pokeDetails,
      families = pokeEdges,
      groups = pokeGroups,
      mobile = isMobile
    )

    # main module (data)
    main <- callModule(
      module = pokeInput,
      id = "input",
      mainData = pokeMain,
      sprites = pokeSprites,
      details = pokeDetails,
      selected = network$selected
    )

    # infos module
    callModule(
      module = pokeInfos,
      id = "infos",
      mainData = pokeMain,
      details = pokeDetails,
      selected = main$pokeSelect,
      shiny = main$pokeShiny
    )

    # stats module
    callModule(
      module = pokeStats,
      id = "stats",
      mainData = pokeMain,
      details = pokeDetails,
      selected = main$pokeSelect
    )

    # types modules
    callModule(
      module = pokeType,
      id = "types",
      types = pokeTypes,
      selected = main$pokeSelect
    )

    # moves module
    callModule(
      module = pokeMove,
      id = "moves",
      selected = main$pokeSelect,
      moves = pokeMoves
    )

  }
)
