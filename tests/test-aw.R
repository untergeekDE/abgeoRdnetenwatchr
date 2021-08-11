library("abgeoRdnetenwatchr")

testthat::test_that("Bundestags- und Landtagswahlen werden gefunden?" {
  testthat::expect_equal(aw_wahl("Bund",2021),128)
  testthat::expect_equal(aw_wahl("Hessen",2017),55)
  testthat::expect_equal(nrow(aw_wahlkreise(55)),55) # Zufall: Wahl 55 hat 55 WK
})

#> Test erfolgreich 🎊